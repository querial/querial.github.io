# AdventureWorks local test lab

Primary workflow is **import-first**:

1. Verify local source/destination databases.
2. Build package trees from canonical SQL sources.
3. Import a package tree or zip in Querial **while the intended project is selected** (import stays in the current project).
4. Run the connection wizard and set endpoints.
5. Publish and run the scenario pipeline(s).

Manual copy/paste from raw SQL files is still available as a fallback. Package import is the default path.

Scenario **F** is the trigger-time external Parquet ingest path (not schedulable). It does not read AdventureWorks.

## Package builder

From this folder (the unzipped lab source):

```powershell
.\build-packages.ps1
.\build-packages.ps1 -Validate
.\build-packages.ps1 -Zip -Validate
.\build-packages.ps1 -Scenarios A,C
.\build-packages.ps1 -Scenarios D,E -Validate
.\build-packages.ps1 -Combined -Validate
.\build-packages.ps1 -Combined -Scenarios A,B,C,D,E,F -Zip
.\build-packages.ps1 -OutDir .\packages
```

Generated output:

```text
packages/
  scenario-a-sqlserver/
  scenario-b-postgres/
  scenario-c-both/
  scenario-d-fanout/
  scenario-e-artifacts/
  scenario-f-ingest/
  aw-lab-all/                   # with -Combined (union of selected scenarios)
  scenario-a-sqlserver.zip      # with -Zip
  scenario-b-postgres.zip       # with -Zip
  scenario-c-both.zip           # with -Zip
  scenario-d-fanout.zip         # with -Zip
  scenario-e-artifacts.zip      # with -Zip
  scenario-f-ingest.zip         # with -Zip
  aw-lab-all.zip                # with -Combined -Zip
```

Each package is `querial.package/v1` and includes:

- `querial.package.yaml`
- `connections/catalog.yaml` (logical stubs only; no secrets)
- `pipelines/*/pipeline.yaml`
- scenario SQL files copied from `migrations/` and `steps/`
- per-pipeline `README.md`

`-Combined` still builds the per-scenario packages for the selected set, then emits one extra package `aw-lab-all` with all selected pipelines and a **union** connection catalog. Use `-Scenarios` to control which scenarios are merged (default A,B,C,D,E,F).

`build-packages.ps1` is idempotent and overwrites `packages/scenario-*` / `packages/aw-lab-all` outputs on rerun.

Set `QUERIAL_PACKAGE_CLI` to a Package CLI `.csproj` if you want checksum-stable `pack` / `validate`. Without it, `-Zip` uses `Compress-Archive` and `-Validate` is a structural check.

## Scenario map

| Scenario | Package | Pipelines | Connections | Step path |
| --- | --- | --- | --- | --- |
| A | `scenario-a-sqlserver` | `aw_scenario_a` | `aw-source`, `aw-sql-dest` | `sql_command` (same-instance MERGE) |
| B | `scenario-b-postgres` | `aw_scenario_b` | `aw-source`, `aw-pg-dest` | Parquet extract + staged PG load |
| C | `scenario-c-both` | `aw_scenario_c` | `aw-source`, `aw-sql-dest`, `aw-pg-dest` | **Multi-root forest**: SS `sql_command` + PG extract/staged (mixed) |
| D | `scenario-d-fanout` | `aw_scenario_d` | `aw-source`, `aw-sql-dest`, `aw-pg-dest` | **Single-root fan-out**: extract → SS `sql_command` + PG staged |
| E | `scenario-e-artifacts` | `aw_scenario_e` | `aw-source`, `aw-sql-dest`, `aw-pg-dest` | **Artifact SQL (DuckDB)**: extract → cast transforms → **join/aggregate** → dual staged sinks |
| F | `scenario-f-ingest` | `aw_scenario_f` | `aw-pg-dest` | **External Parquet ingest**: trigger upload (`external-parquet`) → staged PG `ingest.ids`. **Not schedulable.** |
| Combined (`-Combined`) | `aw-lab-all` | all pipelines from selected scenarios | union of selected catalogs | same as selected scenarios |

### C vs E

| | **C** | **E** |
|---|--------|--------|
| Roots | Multi-root forest (extracts + unbound SS load) | Exactly one root (`extract_sales_order`) |
| SS path | Direct `sql_command` MERGE (re-queries AdventureWorks) | `staged-database-sql` from DuckDB transform |
| Transform | None | CAST `artifact-sql` plus multi-input JOIN/aggregate `artifact-sql` |
| Teaching focus | Independent branches / `continue_independent` | DuckDB Artifact SQL (cast + join) then dual staged sinks |

### DuckDB / Parquet handlers (B, C-PG, D-PG, E, F)

Scenarios **B**, **C** (PostgreSQL half), **D** (PostgreSQL branch), and **E** use extension step types:

- Extract: `database-query-to-parquet` with required unique `config.outputName` (e.g. `product`; no file extension)
- Transform (E): `artifact-sql` with a **list** of `config.inputs[].from_step`, required unique `outputName`, and DuckDB SQL using `{{ input }}` (one inbound file) or `{{ input.outputName }}` (several). CAST steps use the bare token. The join (`transform_order_summary`) uses `{{ input.sales_order_transformed }}` / `{{ input.sales_line_transformed }}` and sinks `aw.sales_order_summary`.
- Load: `staged-database-sql` with a **list** of `config.stages[].from_step`, column contracts, and `transaction.mode: stage-and-execute`. Stage `type` is **destination provider DDL** (SQL Server `datetime2` / `decimal(19,4)`; PostgreSQL `timestamp` / `numeric(19,4)`). Do not put PostgreSQL `timestamptz` on a SQL Server stage (`timestamp` on SQL Server is `rowversion`, not a datetime).
- Extract/transform → load dependencies use `artifact_available`

Map-shaped `stages:` / `inputs:` YAML is rejected. Bindings come from canvas `artifact_available` edges. Package YAML omits frozen `name`; import materializes it from the producer `outputName` so Scenario E join tokens compile.

Scenario **F** is the other Parquet path: an `external-parquet` structural root (no connection, no SQL) that is seeded from a multipart file at trigger (`parquet.ids`), then `staged-database-sql` into `ingest.ids`. It does not extract AdventureWorks. **Do not schedule** F. Canonical fixture: `fixtures/tiny-ids.parquet`.

These need **Artifacts** and **DuckDb** extension flags enabled:

- `Querial__Extensions__Artifacts=true`
- `Querial__Extensions__DuckDb=true`

Scenario **C** is a **single** pipeline (`aw_scenario_c`) that is intentionally a **multi-root forest**. Staged SS variants (`031_*_staged.sql`, `051_*_staged.sql`) remain reference-only under `sql/reference/` in C; Lab **E** promotes them to real steps.

Scenario **D** teaches single-root fan-out and step vs run failure policy (SS load uses `failure_policy: continue`).

Scenario **F** teaches trigger-time file ingest (Run now / `POST /api/trigger` multipart). JSON-only trigger of an F version is 400.

## 0. Prerequisites

- A running Querial instance (Web, API, workers, PostgreSQL control plane)
- Local SQL Server reachable with your credentials
- Full AdventureWorks OLTP (not AdventureWorksLT)
- Empty-ish SQL Server destination catalog (examples use `QuerialAdventureWorks`)

If your source database is `AdventureWorks2019` or `AdventureWorks2022`, update the SQL accordingly before building/importing.

## 1. Verify connections before import

```powershell
.\verify-connections.ps1
# optional:
.\verify-connections.ps1 -AdventureWorksDb AdventureWorks2022 -QuerialSqlDb YourDestName
```

Fix failures first.

## 2. Import package in Querial Web

1. Open **Pipelines** and use **Import package**.
2. Import one of:
   - `packages/scenario-a-sqlserver/` (or `.zip`)
   - `packages/scenario-b-postgres/` (or `.zip`)
   - `packages/scenario-c-both/` (or `.zip`)
   - `packages/scenario-d-fanout/` (or `.zip`)
   - `packages/scenario-e-artifacts/` (or `.zip`)
   - `packages/scenario-f-ingest/` (or `.zip`)
   - `packages/aw-lab-all/` (or `.zip`) when built with `-Combined`
3. Review imported draft pipeline(s) and README from package.

## 3. Connection wizard + endpoints

Create or map logical connections to package names:

- `aw-source` (SQL Server, AdventureWorks)
- `aw-sql-dest` (SQL Server destination warehouse)
- `aw-pg-dest` (PostgreSQL destination warehouse)

Configure Development endpoints and test each one. Scenario F needs only `aw-pg-dest`.

## 4. Publish and run

1. Publish imported draft pipeline version(s).
2. Create deployment(s) for Development.
3. Set default destination connection per pipeline.
4. Activate and run. For F, use **Run now** with `batch_label` and attach `fixtures/tiny-ids.parquet` as `parquet.ids`. Do not schedule F.
5. Verify row counts on destination `aw.*` tables (A–E) or `ingest.ids` (F).

## 5. Fallback manual SQL path

If package import is unavailable, you can still paste SQL manually from:

- `migrations/sqlserver` / `migrations/postgres`
- `steps/A-sqlserver-only`
- `steps/B-postgres-only`
- `steps/C-both`
- `steps/D-fanout`
- `steps/E-artifacts`
- `steps/F-ingest` (load SQL only; the `external-parquet` root must come from package import)

Treat this as fallback only; keep source SQL canonical in these folders and regenerate packages with `build-packages.ps1` after edits.
