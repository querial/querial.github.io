[CmdletBinding()]
param(
    [switch]$Zip,
    [switch]$Validate,
    [switch]$Combined,
    [string[]]$Scenarios = @("A", "B", "C", "D", "E"),
    [string]$OutDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[build-packages] $Message"
}

function Normalize-ScenarioSelection {
    param([string[]]$InputScenarios)

    if (-not $InputScenarios -or $InputScenarios.Count -eq 0) {
        return @("A", "B", "C", "D", "E")
    }

    $allowed = @("A", "B", "C", "D", "E")
    $normalized = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($scenario in $InputScenarios) {
        if ([string]::IsNullOrWhiteSpace($scenario)) {
            continue
        }

        foreach ($token in $scenario.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)) {
            $value = $token.Trim().ToUpperInvariant()
            if ($value.Length -gt 0) {
                [void]$normalized.Add($value)
            }
        }
    }

    $ordered = @($allowed | Where-Object { $normalized.Contains($_) })
    $invalid = @($normalized | Where-Object { $_ -notin $allowed })
    if ($invalid.Count -gt 0) {
        throw "Unknown scenario(s): $($invalid -join ", "). Allowed values: $($allowed -join ", ")."
    }

    if ($ordered.Count -eq 0) {
        throw "No scenarios selected. Allowed values: $($allowed -join ", ")."
    }

    return $ordered
}

function New-CleanDirectory {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Ensure-Directory {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Copy-SqlFile {
    param(
        [string]$SourceRoot,
        [string]$PipelineDir,
        [string]$SourceRelativePath,
        [string]$TargetRelativePath
    )

    $sourcePath = Join-Path $SourceRoot $SourceRelativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing SQL source file: $sourcePath"
    }

    $targetPath = Join-Path $PipelineDir $TargetRelativePath
    Ensure-Directory -Path (Split-Path -Path $targetPath -Parent)
    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    Ensure-Directory -Path (Split-Path -Path $Path -Parent)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Quote-Yaml {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) {
        return "''"
    }

    return "'" + $Value.Replace("'", "''") + "'"
}

function Test-YamlMapping {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [hashtable] -or $Value -is [System.Collections.Specialized.OrderedDictionary]) {
        return $true
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return $true
    }

    # PSCustomObject used as a mapping (step / dependency rows).
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        return $true
    }

    return $false
}

function Get-YamlMappingEntries {
    param($Value)

    $entries = [System.Collections.Generic.List[object]]::new()
    if ($Value -is [hashtable] -or $Value -is [System.Collections.Specialized.OrderedDictionary] -or $Value -is [System.Collections.IDictionary]) {
        foreach ($key in @($Value.Keys)) {
            $entries.Add([pscustomobject]@{ Name = [string]$key; Value = $Value[$key] })
        }

        return @($entries)
    }

    foreach ($property in @($Value.PSObject.Properties)) {
        $entries.Add([pscustomobject]@{ Name = [string]$property.Name; Value = $property.Value })
    }

    return @($entries)
}

function Format-YamlScalar {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return "null"
    }

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int] -or $Value -is [long] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return "$Value"
    }

    return (Quote-Yaml -Value ([string]$Value))
}

function Format-YamlNode {
    param(
        [AllowNull()]$Value,
        [int]$Indent = 0
    )

    $prefix = " " * $Indent
    $lines = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $Value) {
        $lines.Add("${prefix}null")
        return ($lines -join [Environment]::NewLine)
    }

    if (Test-YamlMapping -Value $Value) {
        $entries = @(Get-YamlMappingEntries -Value $Value)
        if ($entries.Count -eq 0) {
            $lines.Add("${prefix}{}")
            return ($lines -join [Environment]::NewLine)
        }

        foreach ($entry in $entries) {
            $child = $entry.Value
            if ($null -eq $child) {
                $lines.Add("$prefix$($entry.Name): null")
                continue
            }

            if (Test-YamlMapping -Value $child) {
                $lines.Add("$prefix$($entry.Name):")
                $lines.Add((Format-YamlNode -Value $child -Indent ($Indent + 2)))
                continue
            }

            if ($child -is [System.Collections.IEnumerable] -and $child -isnot [string]) {
                $childItems = @($child)
                if ($childItems.Count -eq 0) {
                    $lines.Add("$prefix$($entry.Name): []")
                    continue
                }

                $lines.Add("$prefix$($entry.Name):")
                foreach ($childItem in $childItems) {
                    if (Test-YamlMapping -Value $childItem) {
                        $childEntries = @(Get-YamlMappingEntries -Value $childItem)
                        if ($childEntries.Count -eq 0) {
                            $lines.Add("$prefix  - {}")
                            continue
                        }

                        $firstChild = $childEntries[0]
                        if (Test-YamlMapping -Value $firstChild.Value -or (
                                $firstChild.Value -is [System.Collections.IEnumerable] -and $firstChild.Value -isnot [string])) {
                            $lines.Add("$prefix  -")
                            $lines.Add((Format-YamlNode -Value $childItem -Indent ($Indent + 4)))
                        }
                        else {
                            $lines.Add("$prefix  - $($firstChild.Name): $(Format-YamlScalar -Value $firstChild.Value)")
                            for ($i = 1; $i -lt $childEntries.Count; $i++) {
                                $rest = $childEntries[$i]
                                if (Test-YamlMapping -Value $rest.Value) {
                                    $lines.Add("$prefix    $($rest.Name):")
                                    $lines.Add((Format-YamlNode -Value $rest.Value -Indent ($Indent + 6)))
                                }
                                elseif ($rest.Value -is [System.Collections.IEnumerable] -and $rest.Value -isnot [string]) {
                                    $lines.Add("$prefix    $($rest.Name):")
                                    $lines.Add((Format-YamlNode -Value $rest.Value -Indent ($Indent + 6)))
                                }
                                else {
                                    $lines.Add("$prefix    $($rest.Name): $(Format-YamlScalar -Value $rest.Value)")
                                }
                            }
                        }
                    }
                    else {
                        $lines.Add("$prefix  - $(Format-YamlScalar -Value $childItem)")
                    }
                }

                continue
            }

            $lines.Add("$prefix$($entry.Name): $(Format-YamlScalar -Value $child)")
        }

        return ($lines -join [Environment]::NewLine)
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @($Value)
        if ($items.Count -eq 0) {
            $lines.Add("${prefix}[]")
            return ($lines -join [Environment]::NewLine)
        }

        foreach ($item in $items) {
            if (Test-YamlMapping -Value $item) {
                $itemEntries = @(Get-YamlMappingEntries -Value $item)
                if ($itemEntries.Count -eq 0) {
                    $lines.Add("$prefix- {}")
                    continue
                }

                $first = $itemEntries[0]
                if (Test-YamlMapping -Value $first.Value -or (
                        $first.Value -is [System.Collections.IEnumerable] -and $first.Value -isnot [string])) {
                    $lines.Add("$prefix-")
                    $lines.Add((Format-YamlNode -Value $item -Indent ($Indent + 2)))
                }
                else {
                    $lines.Add("$prefix- $($first.Name): $(Format-YamlScalar -Value $first.Value)")
                    for ($i = 1; $i -lt $itemEntries.Count; $i++) {
                        $rest = $itemEntries[$i]
                        if (Test-YamlMapping -Value $rest.Value) {
                            $lines.Add("$prefix  $($rest.Name):")
                            $lines.Add((Format-YamlNode -Value $rest.Value -Indent ($Indent + 4)))
                        }
                        elseif ($rest.Value -is [System.Collections.IEnumerable] -and $rest.Value -isnot [string]) {
                            $lines.Add("$prefix  $($rest.Name):")
                            $lines.Add((Format-YamlNode -Value $rest.Value -Indent ($Indent + 4)))
                        }
                        else {
                            $lines.Add("$prefix  $($rest.Name): $(Format-YamlScalar -Value $rest.Value)")
                        }
                    }
                }
            }
            else {
                $lines.Add("$prefix- $(Format-YamlScalar -Value $item)")
            }
        }

        return ($lines -join [Environment]::NewLine)
    }

    $lines.Add("$prefix$(Format-YamlScalar -Value $Value)")
    return ($lines -join [Environment]::NewLine)
}

function New-StageColumn {
    param(
        [string]$Source,
        [string]$Type,
        [bool]$Nullable = $false,
        [string]$Name = $null
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = $Source
    }

    return [ordered]@{
        source   = $Source
        name     = $Name
        type     = $Type
        nullable = $Nullable
    }
}

function Build-YamlList {
    param([object[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return "[]"
    }

    return (Format-YamlNode -Value $Items -Indent 0)
}

function Indent-Block {
    param(
        [string]$Text,
        [int]$Spaces = 2
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $prefix = " " * $Spaces
    $lines = $Text -split "\r?\n"
    return (($lines | ForEach-Object { "$prefix$_" }) -join [Environment]::NewLine)
}

function Write-ManifestYaml {
    param(
        [string]$PackageDir,
        [hashtable]$ScenarioDefinition
    )

    $pipelineRefs = [System.Collections.Generic.List[object]]::new()
    foreach ($pipeline in $ScenarioDefinition.Pipelines) {
        $pipelineRefs.Add([pscustomobject]@{
                code = $pipeline.Code
                path = "pipelines/$($pipeline.Code)"
            })
    }

    $lines = @(
        "format: querial.package/v1"
        "code: $(Quote-Yaml -Value $ScenarioDefinition.PackageCode)"
        "name: $(Quote-Yaml -Value $ScenarioDefinition.PackageName)"
        "description: $(Quote-Yaml -Value $ScenarioDefinition.PackageDescription)"
        "revision: $(Quote-Yaml -Value $ScenarioDefinition.Revision)"
        "pipelines:"
        (Indent-Block -Text (Build-YamlList -Items $pipelineRefs) -Spaces 2)
    )

    Write-Utf8File -Path (Join-Path $PackageDir "querial.package.yaml") -Content ($lines -join [Environment]::NewLine)
}

function Write-CatalogYaml {
    param(
        [string]$PackageDir,
        [hashtable]$ScenarioDefinition
    )

    $lines = @(
        "connections:"
        (Indent-Block -Text (Build-YamlList -Items $ScenarioDefinition.Connections) -Spaces 2)
    )

    Write-Utf8File -Path (Join-Path $PackageDir "connections/catalog.yaml") -Content ($lines -join [Environment]::NewLine)
}

function Write-PipelineYaml {
    param(
        [string]$PipelineDir,
        [hashtable]$PipelineDefinition,
        [string[]]$ConnectionNames = @()
    )

    $stepLines = (Build-YamlList -Items $PipelineDefinition.Steps)
    $migrationLines = (Build-YamlList -Items $PipelineDefinition.Migrations)
    $dependencyLines = (Build-YamlList -Items $PipelineDefinition.Dependencies)
    $migrationDependencyLines = (Build-YamlList -Items $PipelineDefinition.MigrationDependencies)

    $connectionList = @()
    if ($PipelineDefinition.ContainsKey("ConnectionNames") -and $PipelineDefinition.ConnectionNames) {
        $connectionList = @($PipelineDefinition.ConnectionNames)
    }
    elseif ($ConnectionNames -and $ConnectionNames.Count -gt 0) {
        $connectionList = @($ConnectionNames)
    }

    $connectionLines = if ($connectionList.Count -eq 0) {
        "[]"
    }
    else {
        ($connectionList | ForEach-Object { "- $(Quote-Yaml -Value $_)" }) -join [Environment]::NewLine
    }

    $lines = @(
        "code: $(Quote-Yaml -Value $PipelineDefinition.Code)"
        "name: $(Quote-Yaml -Value $PipelineDefinition.Name)"
        "description: $(Quote-Yaml -Value $PipelineDefinition.Description)"
        "readme: 'README.md'"
        "connections:"
        (Indent-Block -Text $connectionLines -Spaces 2)
        "steps:"
        (Indent-Block -Text $stepLines -Spaces 2)
        "migrations:"
        (Indent-Block -Text $migrationLines -Spaces 2)
        "dependencies:"
        (Indent-Block -Text $dependencyLines -Spaces 2)
        "migration_dependencies:"
        (Indent-Block -Text $migrationDependencyLines -Spaces 2)
    )

    Write-Utf8File -Path (Join-Path $PipelineDir "pipeline.yaml") -Content ($lines -join [Environment]::NewLine)
}

function Invoke-StructuralValidation {
    param([string]$PackageDir)

    $manifestPath = Join-Path $PackageDir "querial.package.yaml"
    $catalogPath = Join-Path $PackageDir "connections/catalog.yaml"

    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Missing manifest: $manifestPath"
    }

    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        throw "Missing catalog: $catalogPath"
    }

    $manifestContent = Get-Content -LiteralPath $manifestPath
    $pipelinePaths = @()
    foreach ($line in $manifestContent) {
        if ($line -match "^\s*path:\s*'?(?<path>[^']+?)'?\s*$") {
            $pipelinePaths += $matches["path"].Trim()
        }
    }

    if ($pipelinePaths.Count -eq 0) {
        throw "Manifest has no pipeline paths: $manifestPath"
    }

    $catalogContent = Get-Content -LiteralPath $catalogPath
    $catalogNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($line in $catalogContent) {
        if ($line -match "^\s*-\s*name:\s*'?(?<name>[^']+?)'?\s*$") {
            [void]$catalogNames.Add($matches["name"].Trim())
        }
    }

    foreach ($pipelinePath in $pipelinePaths) {
        $pipelineDir = Join-Path $PackageDir ($pipelinePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar))
        $pipelineYamlPath = Join-Path $pipelineDir "pipeline.yaml"
        if (-not (Test-Path -LiteralPath $pipelineYamlPath -PathType Leaf)) {
            throw "Missing pipeline definition: $pipelineYamlPath"
        }

        $yamlLines = Get-Content -LiteralPath $pipelineYamlPath
        foreach ($line in $yamlLines) {
            if ($line -match "^\s*sql:\s*'?(?<sql>[^']+?)'?\s*$") {
                $sqlRel = $matches["sql"].Trim()
                $sqlPath = Join-Path $pipelineDir ($sqlRel.Replace("/", [System.IO.Path]::DirectorySeparatorChar))
                if (-not (Test-Path -LiteralPath $sqlPath -PathType Leaf)) {
                    throw "Referenced SQL does not exist: $sqlPath"
                }
            }

            if ($line -match "^\s*connection:\s*'?(?<conn>[^']+?)'?\s*$") {
                $connection = $matches["conn"].Trim()
                if ($connection -ne "null" -and -not $catalogNames.Contains($connection)) {
                    throw "Referenced connection '$connection' is not in catalog.yaml for $pipelineYamlPath"
                }
            }
        }
    }
}

function Invoke-PackageValidation {
    param(
        [string]$PackageDir,
        [bool]$PackageCliAvailable,
        [string]$PackageCliProject
    )

    if ($PackageCliAvailable) {
        Write-Info "Validating with PackageCli: $PackageDir"
        $args = @(
            "run"
            "--project"
            $PackageCliProject
            "--"
            "validate"
            $PackageDir
        )

        & dotnet @args
        if ($LASTEXITCODE -ne 0) {
            throw "PackageCli validation failed for $PackageDir."
        }
    }
    else {
        Write-Info "PackageCli not found. Running structural validation: $PackageDir"
        Invoke-StructuralValidation -PackageDir $PackageDir
    }
}

function Invoke-PackageZip {
    param(
        [string]$PackageDir,
        [string]$ZipPath,
        [bool]$PackageCliAvailable,
        [string]$PackageCliProject
    )

    if ($PackageCliAvailable) {
        Write-Info "Packing deterministic zip with PackageCli: $ZipPath"
        $args = @(
            "run"
            "--project"
            $PackageCliProject
            "--"
            "pack"
            $PackageDir
            $ZipPath
        )

        & dotnet @args
        if ($LASTEXITCODE -ne 0) {
            throw "PackageCli pack failed for $PackageDir."
        }
        return
    }

    Write-Info "PackageCli not found. Creating fallback zip with Compress-Archive: $ZipPath"
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    Compress-Archive -Path (Join-Path $PackageDir "*") -DestinationPath $ZipPath -CompressionLevel Optimal -Force
}

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$sourceRoot = $scriptRoot
$selectedScenarios = Normalize-ScenarioSelection -InputScenarios $Scenarios
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $outputRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot "packages"))
}
elseif ([System.IO.Path]::IsPathRooted($OutDir)) {
    $outputRoot = [System.IO.Path]::GetFullPath($OutDir)
}
else {
    $outputRoot = [System.IO.Path]::GetFullPath((Join-Path $sourceRoot $OutDir))
}

# Optional: set QUERIAL_PACKAGE_CLI to a Package CLI .csproj for checksum-stable zips.
# Without it, -Zip uses Compress-Archive and -Validate does a structural file check.
$packageCliProject = $env:QUERIAL_PACKAGE_CLI
$packageCliAvailable = -not [string]::IsNullOrWhiteSpace($packageCliProject) -and (Test-Path -LiteralPath $packageCliProject -PathType Leaf)

$scenarioDefinitions = @{
    "A" = @{
        ScenarioCode = "A"
        PackageDirectory = "scenario-a-sqlserver"
        PackageCode = "aw-scenario-a"
        PackageName = "AdventureWorks Scenario A"
        PackageDescription = "SQL Server destination scenario for person and customer loads."
        Revision = "phase6-lab-v1"
        Connections = @(
            [pscustomobject]@{ name = "aw-source"; provider = "sqlserver"; description = "AdventureWorks source logical connection stub." }
            [pscustomobject]@{ name = "aw-sql-dest"; provider = "sqlserver"; description = "SQL Server destination logical connection stub." }
        )
        Pipelines = @(
            @{
                Code = "aw_scenario_a"
                Name = "AW Scenario A SQL Server"
                Description = "Scenario A SQL Server-only load path."
                Readme = @'
# AW Scenario A (SQL Server destination)

This pipeline imports the AdventureWorks person/customer subset into SQL Server destination tables under schema `aw`.

## Connections

- `aw-sql-dest` for migrations and load steps.
- `aw-source` is present in the package catalog for consistency with lab naming, but Scenario A uses same-instance three-part names and does not bind extract steps.

## Steps

1. `load_person` from `AdventureWorks.Person.Person` into `aw.person`.
2. `load_customer` from `AdventureWorks.Sales.Customer` into `aw.customer` (depends on `load_person`).

All steps are `sql_command` and idempotent (`MERGE`).
'@
                Migrations = @(
                    [pscustomobject]@{ code = "001_create_schema"; name = "Create aw schema"; execution_order = 1; connection = "aw-sql-dest"; sql = "sql/migrations/001_create_schema.sql" }
                    [pscustomobject]@{ code = "002_create_person"; name = "Create aw.person"; execution_order = 2; connection = "aw-sql-dest"; sql = "sql/migrations/002_create_person.sql" }
                    [pscustomobject]@{ code = "003_create_customer"; name = "Create aw.customer"; execution_order = 3; connection = "aw-sql-dest"; sql = "sql/migrations/003_create_customer.sql" }
                )
                MigrationDependencies = @(
                    [pscustomobject]@{ from = "001_create_schema"; to = "002_create_person" }
                    [pscustomobject]@{ from = "002_create_person"; to = "003_create_customer" }
                )
                Steps = @(
                    [pscustomobject]@{ code = "load_person"; name = "Load person"; type = "sql_command"; execution_order = 10; connection = "aw-sql-dest"; sql = "sql/steps/010_load_person.sql" }
                    [pscustomobject]@{ code = "load_customer"; name = "Load customer"; type = "sql_command"; execution_order = 20; connection = "aw-sql-dest"; sql = "sql/steps/020_load_customer.sql" }
                )
                Dependencies = @(
                    [pscustomobject]@{ from = "load_person"; to = "load_customer"; requirement = "required" }
                )
                SqlCopies = @(
                    [pscustomobject]@{ Source = "migrations/sqlserver/001_create_schema.sql"; Target = "sql/migrations/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/002_create_person.sql"; Target = "sql/migrations/002_create_person.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/003_create_customer.sql"; Target = "sql/migrations/003_create_customer.sql" }
                    [pscustomobject]@{ Source = "steps/A-sqlserver-only/010_load_person.sql"; Target = "sql/steps/010_load_person.sql" }
                    [pscustomobject]@{ Source = "steps/A-sqlserver-only/020_load_customer.sql"; Target = "sql/steps/020_load_customer.sql" }
                )
            }
        )
    }
    "B" = @{
        ScenarioCode = "B"
        PackageDirectory = "scenario-b-postgres"
        PackageCode = "aw-scenario-b"
        PackageName = "AdventureWorks Scenario B"
        PackageDescription = "PostgreSQL destination scenario for product extract and staged load SQL."
        Revision = "phase6-lab-v1"
        Connections = @(
            [pscustomobject]@{ name = "aw-source"; provider = "sqlserver"; description = "AdventureWorks source logical connection stub." }
            [pscustomobject]@{ name = "aw-pg-dest"; provider = "postgresql"; description = "PostgreSQL destination logical connection stub." }
        )
        Pipelines = @(
            @{
                Code = "aw_scenario_b"
                Name = "AW Scenario B PostgreSQL"
                Description = "Scenario B product load path for PostgreSQL destination."
                Readme = @'
# AW Scenario B (PostgreSQL destination)

This pipeline extracts AdventureWorks products to Parquet and loads them into PostgreSQL via staged-database-sql.

## Connections

- `aw-source` for `database-query-to-parquet` extract.
- `aw-pg-dest` for migrations and `staged-database-sql` load.

## Steps

1. `extract_product` (`database-query-to-parquet`) writes artifact `product`.
2. `load_product` (`staged-database-sql`) stages that artifact as `product` and upserts into `aw.product`.

Dependency `extract_product` -> `load_product` uses `artifact_available`.

## Runtime flags

Requires `Querial:Extensions:Artifacts` and `Querial:Extensions:DuckDb` (Aspire AppHost enables both for local lab).
'@
                Migrations = @(
                    [pscustomobject]@{ code = "001_create_schema"; name = "Create aw schema"; execution_order = 1; connection = "aw-pg-dest"; sql = "sql/migrations/001_create_schema.sql" }
                    [pscustomobject]@{ code = "004_create_product"; name = "Create aw.product"; execution_order = 2; connection = "aw-pg-dest"; sql = "sql/migrations/004_create_product.sql" }
                )
                MigrationDependencies = @(
                    [pscustomobject]@{ from = "001_create_schema"; to = "004_create_product" }
                )
                Steps = @(
                    [pscustomobject]@{
                        code            = "extract_product"
                        name            = "Extract product"
                        type            = "database-query-to-parquet"
                        execution_order = 10
                        connection      = "aw-source"
                        sql             = "sql/steps/010_extract_product.sql"
                        config          = [ordered]@{
                            outputName = "product"
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_product"
                        name            = "Load product"
                        type            = "staged-database-sql"
                        execution_order = 20
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/020_load_product.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                product = [ordered]@{
                                    from_step = "extract_product"
                                    columns   = @(
                                        (New-StageColumn -Source "product_id" -Type "int")
                                        (New-StageColumn -Source "name" -Type "text")
                                        (New-StageColumn -Source "product_number" -Type "text")
                                        (New-StageColumn -Source "color" -Type "text" -Nullable $true)
                                        (New-StageColumn -Source "standard_cost" -Type "numeric")
                                        (New-StageColumn -Source "list_price" -Type "numeric")
                                        (New-StageColumn -Source "sell_start_date" -Type "timestamptz")
                                        (New-StageColumn -Source "modified_date" -Type "timestamptz")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                )
                Dependencies = @(
                    [pscustomobject]@{ from = "extract_product"; to = "load_product"; requirement = "artifact_available" }
                )
                SqlCopies = @(
                    [pscustomobject]@{ Source = "migrations/postgres/001_create_schema.sql"; Target = "sql/migrations/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/004_create_product.sql"; Target = "sql/migrations/004_create_product.sql" }
                    [pscustomobject]@{ Source = "steps/B-postgres-only/010_extract_product.sql"; Target = "sql/steps/010_extract_product.sql" }
                    [pscustomobject]@{ Source = "steps/B-postgres-only/020_load_product.sql"; Target = "sql/steps/020_load_product.sql" }
                )
            }
        )
    }
    "C" = @{
        ScenarioCode = "C"
        PackageDirectory = "scenario-c-both"
        PackageCode = "aw-scenario-c"
        PackageName = "AdventureWorks Scenario C"
        PackageDescription = "Dual-destination sales scenario: one pipeline loads SQL Server and PostgreSQL."
        Revision = "phase6-lab-v2"
        Connections = @(
            [pscustomobject]@{ name = "aw-source"; provider = "sqlserver"; description = "AdventureWorks source logical connection stub." }
            [pscustomobject]@{ name = "aw-sql-dest"; provider = "sqlserver"; description = "SQL Server destination logical connection stub." }
            [pscustomobject]@{ name = "aw-pg-dest"; provider = "postgresql"; description = "PostgreSQL destination logical connection stub." }
        )
        Pipelines = @(
            @{
                Code = "aw_scenario_c"
                Name = "AW Scenario C Both Destinations"
                Description = "Single multi-connection pipeline: SQL Server sql_command loads plus PostgreSQL parquet extract and staged loads."
                Readme = @'
# AW Scenario C (SQL Server + PostgreSQL) - multi-root forest

One pipeline, three logical connections. SQL Server loads use `sql_command`; PostgreSQL uses Parquet extract + `staged-database-sql`.

## Topology (ADR 0023)

This DAG is a **multi-root forest**: several steps have no upstream edges and become Ready together.

Typical structural roots:

1. `extract_sales_order`
2. `extract_sales_line`
3. `load_sales_order_sqlserver` (SS path re-queries AdventureWorks; it does not depend on the extracts)

Contrast with Lab **D** (single-root fan-out) and Lab **E** (single-root parquet -> artifact-sql -> dual staged sinks).

## Failure policy testing

Import, publish, then set run-level `dag_failure_policy` to `continue_independent` (pipeline default or deployment override) and fail one independent branch (for example break the SS MERGE). Sibling roots/branches should keep running. With `fail_fast`, only a `fail_pipeline` step failure latches the whole run.

## Connections

- `aw-source` - AdventureWorks extracts (PostgreSQL path)
- `aw-sql-dest` - SQL Server migrations and MERGE loads
- `aw-pg-dest` - PostgreSQL migrations and staged loads

## Steps

1. `extract_sales_order` / `extract_sales_line` (source -> parquet)
2. `load_sales_order_sqlserver` -> `load_sales_line_sqlserver`
3. `load_sales_order_postgres` / `load_sales_line_postgres` (artifact_available from extracts)

SS and PG branches run independently after extracts; there is no distributed transaction across destinations.

## Runtime flags

PostgreSQL half requires `Querial:Extensions:Artifacts` and `Querial:Extensions:DuckDb`.

## Staged SQL reference (SS)

Reference-only under this package (promoted to real steps in Lab **E**):

- `sql/reference/031_load_sales_order_sqlserver_staged.sql`
- `sql/reference/051_load_sales_line_sqlserver_staged.sql`
'@
                Migrations = @(
                    [pscustomobject]@{ code = "ss_001_create_schema"; name = "Create aw schema (SQL Server)"; execution_order = 1; connection = "aw-sql-dest"; sql = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ code = "ss_005_create_sales"; name = "Create aw.sales tables (SQL Server)"; execution_order = 2; connection = "aw-sql-dest"; sql = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ code = "pg_001_create_schema"; name = "Create aw schema (PostgreSQL)"; execution_order = 3; connection = "aw-pg-dest"; sql = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ code = "pg_005_create_sales"; name = "Create aw.sales tables (PostgreSQL)"; execution_order = 4; connection = "aw-pg-dest"; sql = "sql/migrations/pg/005_create_sales.sql" }
                )
                MigrationDependencies = @(
                    [pscustomobject]@{ from = "ss_001_create_schema"; to = "ss_005_create_sales" }
                    [pscustomobject]@{ from = "pg_001_create_schema"; to = "pg_005_create_sales" }
                )
                Steps = @(
                    [pscustomobject]@{
                        code            = "extract_sales_order"
                        name            = "Extract sales order"
                        type            = "database-query-to-parquet"
                        execution_order = 10
                        connection      = "aw-source"
                        sql             = "sql/steps/010_extract_sales_order.sql"
                        config          = [ordered]@{
                            outputName = "sales_order"
                        }
                    }
                    [pscustomobject]@{
                        code            = "extract_sales_line"
                        name            = "Extract sales line"
                        type            = "database-query-to-parquet"
                        execution_order = 20
                        connection      = "aw-source"
                        sql             = "sql/steps/020_extract_sales_line.sql"
                        config          = [ordered]@{
                            outputName = "sales_line"
                        }
                    }
                    [pscustomobject]@{ code = "load_sales_order_sqlserver"; name = "Load sales order (SQL Server)"; type = "sql_command"; execution_order = 30; connection = "aw-sql-dest"; sql = "sql/steps/030_load_sales_order_sqlserver.sql" }
                    [pscustomobject]@{
                        code            = "load_sales_order_postgres"
                        name            = "Load sales order (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 40
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/040_load_sales_order_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "extract_sales_order"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "order_date" -Type "timestamptz")
                                        (New-StageColumn -Source "status" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "total_due" -Type "numeric")
                                        (New-StageColumn -Source "modified_date" -Type "timestamptz")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{ code = "load_sales_line_sqlserver"; name = "Load sales line (SQL Server)"; type = "sql_command"; execution_order = 50; connection = "aw-sql-dest"; sql = "sql/steps/050_load_sales_line_sqlserver.sql" }
                    [pscustomobject]@{
                        code            = "load_sales_line_postgres"
                        name            = "Load sales line (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 60
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/060_load_sales_line_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_line = [ordered]@{
                                    from_step = "extract_sales_line"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "sales_order_detail_id" -Type "int")
                                        (New-StageColumn -Source "product_id" -Type "int")
                                        (New-StageColumn -Source "order_qty" -Type "int")
                                        (New-StageColumn -Source "unit_price" -Type "numeric")
                                        (New-StageColumn -Source "line_total" -Type "numeric")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                )
                Dependencies = @(
                    [pscustomobject]@{ from = "load_sales_order_sqlserver"; to = "load_sales_line_sqlserver"; requirement = "required" }
                    [pscustomobject]@{ from = "extract_sales_order"; to = "load_sales_order_postgres"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "extract_sales_line"; to = "load_sales_line_postgres"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "load_sales_order_postgres"; to = "load_sales_line_postgres"; requirement = "required" }
                )
                SqlCopies = @(
                    [pscustomobject]@{ Source = "migrations/sqlserver/001_create_schema.sql"; Target = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/005_create_sales.sql"; Target = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/001_create_schema.sql"; Target = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/005_create_sales.sql"; Target = "sql/migrations/pg/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/010_extract_sales_order.sql"; Target = "sql/steps/010_extract_sales_order.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/020_extract_sales_line.sql"; Target = "sql/steps/020_extract_sales_line.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/030_load_sales_order_sqlserver.sql"; Target = "sql/steps/030_load_sales_order_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/040_load_sales_order_postgres.sql"; Target = "sql/steps/040_load_sales_order_postgres.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/050_load_sales_line_sqlserver.sql"; Target = "sql/steps/050_load_sales_line_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/060_load_sales_line_postgres.sql"; Target = "sql/steps/060_load_sales_line_postgres.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/031_load_sales_order_sqlserver_staged.sql"; Target = "sql/reference/031_load_sales_order_sqlserver_staged.sql" }
                    [pscustomobject]@{ Source = "steps/C-both/051_load_sales_line_sqlserver_staged.sql"; Target = "sql/reference/051_load_sales_line_sqlserver_staged.sql" }
                )
            }
        )
    }
    "D" = @{
        ScenarioCode = "D"
        PackageDirectory = "scenario-d-fanout"
        PackageCode = "aw-scenario-d"
        PackageName = "AdventureWorks Scenario D"
        PackageDescription = "Single-root fan-out: one extract, then SQL Server sql_command and PostgreSQL staged loads."
        Revision = "adr0023-lab-v1"
        Connections = @(
            [pscustomobject]@{ name = "aw-source"; provider = "sqlserver"; description = "AdventureWorks source logical connection stub." }
            [pscustomobject]@{ name = "aw-sql-dest"; provider = "sqlserver"; description = "SQL Server destination logical connection stub." }
            [pscustomobject]@{ name = "aw-pg-dest"; provider = "postgresql"; description = "PostgreSQL destination logical connection stub." }
        )
        Pipelines = @(
            @{
                Code = "aw_scenario_d"
                Name = "AW Scenario D Fan-Out"
                Description = "Single structural root fan-out teaching topology and failure policy."
                Readme = @'
# AW Scenario D - single-root fan-out

One extract is the **only** structural root. Both destination loads depend on it.

## Topology (ADR 0023)

```text
extract_sales_order  (ROOT)
  |--(succeeded)----------> load_sales_order_sqlserver   (sql_command, re-queries source)
  +--(artifact_available)-> load_sales_order_postgres  (staged-database-sql)
```

Contrast with Lab **C**: C is a **multi-root forest** (independent extracts and an unbound SS load start together). D forces a shared upstream so there is exactly one entry point.

## Failure policy

- SS load uses step `failure_policy: continue` so a SS MERGE failure does not latch fail-fast; the PG branch can still finish under run-level `fail_fast`.
- Optionally set pipeline/deployment `dag_failure_policy` to `continue_independent` to keep independent branches alive when a `fail_pipeline` step fails elsewhere.

## Connections

- `aw-source` - extract
- `aw-sql-dest` - migrations + MERGE
- `aw-pg-dest` - migrations + staged load

## Runtime flags

PostgreSQL branch requires `Querial:Extensions:Artifacts` and `Querial:Extensions:DuckDb`.
'@
                Migrations = @(
                    [pscustomobject]@{ code = "ss_001_create_schema"; name = "Create aw schema (SQL Server)"; execution_order = 1; connection = "aw-sql-dest"; sql = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ code = "ss_005_create_sales"; name = "Create aw.sales tables (SQL Server)"; execution_order = 2; connection = "aw-sql-dest"; sql = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ code = "pg_001_create_schema"; name = "Create aw schema (PostgreSQL)"; execution_order = 3; connection = "aw-pg-dest"; sql = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ code = "pg_005_create_sales"; name = "Create aw.sales tables (PostgreSQL)"; execution_order = 4; connection = "aw-pg-dest"; sql = "sql/migrations/pg/005_create_sales.sql" }
                )
                MigrationDependencies = @(
                    [pscustomobject]@{ from = "ss_001_create_schema"; to = "ss_005_create_sales" }
                    [pscustomobject]@{ from = "pg_001_create_schema"; to = "pg_005_create_sales" }
                )
                Steps = @(
                    [pscustomobject]@{
                        code            = "extract_sales_order"
                        name            = "Extract sales order"
                        type            = "database-query-to-parquet"
                        execution_order = 10
                        connection      = "aw-source"
                        sql             = "sql/steps/010_extract_sales_order.sql"
                        config          = [ordered]@{
                            outputName = "sales_order"
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_sales_order_sqlserver"
                        name            = "Load sales order (SQL Server)"
                        type            = "sql_command"
                        execution_order = 20
                        connection      = "aw-sql-dest"
                        failure_policy  = "continue"
                        sql             = "sql/steps/020_load_sales_order_sqlserver.sql"
                    }
                    [pscustomobject]@{
                        code            = "load_sales_order_postgres"
                        name            = "Load sales order (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 30
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/030_load_sales_order_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "extract_sales_order"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "order_date" -Type "timestamptz")
                                        (New-StageColumn -Source "status" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "total_due" -Type "numeric")
                                        (New-StageColumn -Source "modified_date" -Type "timestamptz")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                )
                Dependencies = @(
                    [pscustomobject]@{ from = "extract_sales_order"; to = "load_sales_order_sqlserver"; requirement = "succeeded" }
                    [pscustomobject]@{ from = "extract_sales_order"; to = "load_sales_order_postgres"; requirement = "artifact_available" }
                )
                SqlCopies = @(
                    [pscustomobject]@{ Source = "migrations/sqlserver/001_create_schema.sql"; Target = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/005_create_sales.sql"; Target = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/001_create_schema.sql"; Target = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/005_create_sales.sql"; Target = "sql/migrations/pg/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "steps/D-fanout/010_extract_sales_order.sql"; Target = "sql/steps/010_extract_sales_order.sql" }
                    [pscustomobject]@{ Source = "steps/D-fanout/020_load_sales_order_sqlserver.sql"; Target = "sql/steps/020_load_sales_order_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/D-fanout/030_load_sales_order_postgres.sql"; Target = "sql/steps/030_load_sales_order_postgres.sql" }
                )
            }
        )
    }
    "E" = @{
        ScenarioCode = "E"
        PackageDirectory = "scenario-e-artifacts"
        PackageCode = "aw-scenario-e"
        PackageName = "AdventureWorks Scenario E"
        PackageDescription = "Parquet spine with DuckDB artifact-sql: single-input casts, multi-input join/aggregate, dual staged sinks."
        Revision = "duckdb-join-v1"
        Connections = @(
            [pscustomobject]@{ name = "aw-source"; provider = "sqlserver"; description = "AdventureWorks source logical connection stub." }
            [pscustomobject]@{ name = "aw-sql-dest"; provider = "sqlserver"; description = "SQL Server destination logical connection stub." }
            [pscustomobject]@{ name = "aw-pg-dest"; provider = "postgresql"; description = "PostgreSQL destination logical connection stub." }
        )
        Pipelines = @(
            @{
                Code = "aw_scenario_e"
                Name = "AW Scenario E Artifacts"
                Description = "Extract -> DuckDB artifact-sql (cast + join/aggregate) -> dual staged sinks."
                Readme = @'
# AW Scenario E - Artifact SQL (DuckDB)

Full Parquet path with a **single structural root**. This lab is the Artifact SQL teaching package:

1. Single-input `artifact-sql` (CAST/filter on one Parquet).
2. Multi-input `artifact-sql` (INNER JOIN + GROUP BY over two Parquet artifacts).
3. Dual `staged-database-sql` sinks (SQL Server and PostgreSQL) — including the DuckDB rollup table `aw.sales_order_summary`.

There is no database connection on `artifact-sql` steps. DuckDB runs embedded in an eligible agent.

## Topology (ADR 0023)

```text
extract_sales_order (ROOT, parquet)
  |--(artifact_available)-> transform_sales_order (artifact-sql, one input)
  |                           |--> load_sales_order_sqlserver (staged)
  |                           +--> load_sales_order_postgres (staged)
  |                           +--> transform_order_summary (artifact-sql, TWO inputs)
  |                                 |--> load_order_summary_sqlserver (staged)
  |                                 +--> load_order_summary_postgres (staged)
  +--(succeeded)----------> extract_sales_line
                              +--(artifact_available)-> transform_sales_line (artifact-sql, one input)
                                                          |--> load_sales_line_sqlserver (staged)
                                                          +--> load_sales_line_postgres (staged)
                                                          +--> transform_order_summary (second input)
```

All artifact edges use `artifact_available`. Line extract hangs off the order extract so the graph stays single-root (unlike Lab **C**).

## DuckDB SQL

- `transform_sales_order` / `transform_sales_line` read `{{ input.sales_order }}` / `{{ input.sales_line }}` (one `from_step` each).
- `transform_order_summary` joins both transformed artifacts:

```sql
FROM {{ input.sales_order }} AS o
INNER JOIN {{ input.sales_line }} AS l
    ON o.sales_order_id = l.sales_order_id
GROUP BY ...
```

`config.inputs.<name>.from_step` must match those input names. `config.outputName` is required and unique.

## Lab contrast

| Lab | Focus |
|-----|--------|
| **B** | Minimal PG: extract -> staged PG only |
| **C** | Multi-root forest; SS `sql_command` + PG staged (mixed) |
| **D** | Topology + failure policy: single-root fan-out |
| **E** | Artifact SQL: extract -> DuckDB (cast + join) -> dual staged sinks |

SS staged MERGE scripts are **real steps** here (promoted from C `sql/reference/031_*` / `051_*`).

## Connections

- `aw-source` - extracts
- `aw-sql-dest` - migrations + staged MERGE
- `aw-pg-dest` - migrations + staged upsert

## Runtime flags (required)

Requires **both**:

- `Querial:Extensions:Artifacts=true`
- `Querial:Extensions:DuckDb=true`

Enable both flags on your Querial instance.

## Failed-cone recovery (ADR 0027 Lab E)

1. Run the pipeline with `DagExecution=true` (plus Artifacts + DuckDb).
2. Fail **one** staged sink (for example `load_sales_order_sqlserver`) while the extract, `artifact-sql` transforms, and the sibling sink succeed.
3. Retry the failed run with mode **failed cone** (not full).
4. Confirm: the failed sink is the only step leased again; extract and transforms stay `succeeded` with `outcome_reason=reused`; cloned artifact checksums match the source; the sibling sink is not re-executed.

Full retry still re-extracts. Same-agent ArtifactLocalizer cache (no re-download) is not skip-extract.
'@
                Migrations = @(
                    [pscustomobject]@{ code = "ss_001_create_schema"; name = "Create aw schema (SQL Server)"; execution_order = 1; connection = "aw-sql-dest"; sql = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ code = "ss_005_create_sales"; name = "Create aw.sales tables (SQL Server)"; execution_order = 2; connection = "aw-sql-dest"; sql = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ code = "ss_006_create_sales_summary"; name = "Create aw.sales_order_summary (SQL Server)"; execution_order = 3; connection = "aw-sql-dest"; sql = "sql/migrations/ss/006_create_sales_summary.sql" }
                    [pscustomobject]@{ code = "pg_001_create_schema"; name = "Create aw schema (PostgreSQL)"; execution_order = 4; connection = "aw-pg-dest"; sql = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ code = "pg_005_create_sales"; name = "Create aw.sales tables (PostgreSQL)"; execution_order = 5; connection = "aw-pg-dest"; sql = "sql/migrations/pg/005_create_sales.sql" }
                    [pscustomobject]@{ code = "pg_006_create_sales_summary"; name = "Create aw.sales_order_summary (PostgreSQL)"; execution_order = 6; connection = "aw-pg-dest"; sql = "sql/migrations/pg/006_create_sales_summary.sql" }
                )
                MigrationDependencies = @(
                    [pscustomobject]@{ from = "ss_001_create_schema"; to = "ss_005_create_sales" }
                    [pscustomobject]@{ from = "ss_005_create_sales"; to = "ss_006_create_sales_summary" }
                    [pscustomobject]@{ from = "pg_001_create_schema"; to = "pg_005_create_sales" }
                    [pscustomobject]@{ from = "pg_005_create_sales"; to = "pg_006_create_sales_summary" }
                )
                Steps = @(
                    [pscustomobject]@{
                        code            = "extract_sales_order"
                        name            = "Extract sales order"
                        type            = "database-query-to-parquet"
                        execution_order = 10
                        connection      = "aw-source"
                        sql             = "sql/steps/010_extract_sales_order.sql"
                        config          = [ordered]@{
                            outputName = "sales_order"
                        }
                    }
                    [pscustomobject]@{
                        code            = "extract_sales_line"
                        name            = "Extract sales line"
                        type            = "database-query-to-parquet"
                        execution_order = 20
                        connection      = "aw-source"
                        sql             = "sql/steps/020_extract_sales_line.sql"
                        config          = [ordered]@{
                            outputName = "sales_line"
                        }
                    }
                    [pscustomobject]@{
                        code            = "transform_sales_order"
                        name            = "Transform sales order (DuckDB)"
                        type            = "artifact-sql"
                        execution_order = 30
                        sql             = "sql/steps/030_transform_sales_order.sql"
                        config          = [ordered]@{
                            outputName = "sales_order_transformed"
                            inputs     = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "extract_sales_order"
                                }
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "transform_sales_line"
                        name            = "Transform sales line (DuckDB)"
                        type            = "artifact-sql"
                        execution_order = 40
                        sql             = "sql/steps/040_transform_sales_line.sql"
                        config          = [ordered]@{
                            outputName = "sales_line_transformed"
                            inputs     = [ordered]@{
                                sales_line = [ordered]@{
                                    from_step = "extract_sales_line"
                                }
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "transform_order_summary"
                        name            = "Join orders and lines (DuckDB)"
                        type            = "artifact-sql"
                        execution_order = 45
                        sql             = "sql/steps/045_transform_order_summary.sql"
                        config          = [ordered]@{
                            outputName = "order_summary"
                            inputs     = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "transform_sales_order"
                                }
                                sales_line  = [ordered]@{
                                    from_step = "transform_sales_line"
                                }
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_sales_order_sqlserver"
                        name            = "Load sales order (SQL Server staged)"
                        type            = "staged-database-sql"
                        execution_order = 50
                        connection      = "aw-sql-dest"
                        sql             = "sql/steps/050_load_sales_order_sqlserver.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "transform_sales_order"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "order_date" -Type "timestamptz")
                                        (New-StageColumn -Source "status" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "total_due" -Type "numeric")
                                        (New-StageColumn -Source "modified_date" -Type "timestamptz")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_sales_order_postgres"
                        name            = "Load sales order (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 60
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/060_load_sales_order_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_order = [ordered]@{
                                    from_step = "transform_sales_order"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "order_date" -Type "timestamptz")
                                        (New-StageColumn -Source "status" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "total_due" -Type "numeric")
                                        (New-StageColumn -Source "modified_date" -Type "timestamptz")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_sales_line_sqlserver"
                        name            = "Load sales line (SQL Server staged)"
                        type            = "staged-database-sql"
                        execution_order = 70
                        connection      = "aw-sql-dest"
                        sql             = "sql/steps/070_load_sales_line_sqlserver.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_line = [ordered]@{
                                    from_step = "transform_sales_line"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "sales_order_detail_id" -Type "int")
                                        (New-StageColumn -Source "product_id" -Type "int")
                                        (New-StageColumn -Source "order_qty" -Type "int")
                                        (New-StageColumn -Source "unit_price" -Type "numeric")
                                        (New-StageColumn -Source "line_total" -Type "numeric")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_sales_line_postgres"
                        name            = "Load sales line (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 80
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/080_load_sales_line_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                sales_line = [ordered]@{
                                    from_step = "transform_sales_line"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "sales_order_detail_id" -Type "int")
                                        (New-StageColumn -Source "product_id" -Type "int")
                                        (New-StageColumn -Source "order_qty" -Type "int")
                                        (New-StageColumn -Source "unit_price" -Type "numeric")
                                        (New-StageColumn -Source "line_total" -Type "numeric")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_order_summary_sqlserver"
                        name            = "Load order summary (SQL Server staged)"
                        type            = "staged-database-sql"
                        execution_order = 90
                        connection      = "aw-sql-dest"
                        sql             = "sql/steps/090_load_order_summary_sqlserver.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                order_summary = [ordered]@{
                                    from_step = "transform_order_summary"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "order_day" -Type "date")
                                        (New-StageColumn -Source "line_count" -Type "int")
                                        (New-StageColumn -Source "total_qty" -Type "int")
                                        (New-StageColumn -Source "computed_line_total" -Type "numeric")
                                        (New-StageColumn -Source "header_total_due" -Type "numeric")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                    [pscustomobject]@{
                        code            = "load_order_summary_postgres"
                        name            = "Load order summary (PostgreSQL)"
                        type            = "staged-database-sql"
                        execution_order = 100
                        connection      = "aw-pg-dest"
                        sql             = "sql/steps/100_load_order_summary_postgres.sql"
                        config          = [ordered]@{
                            stages = [ordered]@{
                                order_summary = [ordered]@{
                                    from_step = "transform_order_summary"
                                    columns   = @(
                                        (New-StageColumn -Source "sales_order_id" -Type "int")
                                        (New-StageColumn -Source "customer_id" -Type "int")
                                        (New-StageColumn -Source "order_day" -Type "date")
                                        (New-StageColumn -Source "line_count" -Type "int")
                                        (New-StageColumn -Source "total_qty" -Type "int")
                                        (New-StageColumn -Source "computed_line_total" -Type "numeric")
                                        (New-StageColumn -Source "header_total_due" -Type "numeric")
                                    )
                                }
                            }
                            transaction = [ordered]@{
                                mode = "stage-and-execute"
                            }
                        }
                    }
                )
                Dependencies = @(
                    [pscustomobject]@{ from = "extract_sales_order"; to = "extract_sales_line"; requirement = "succeeded" }
                    [pscustomobject]@{ from = "extract_sales_order"; to = "transform_sales_order"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "extract_sales_line"; to = "transform_sales_line"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_order"; to = "transform_order_summary"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_line"; to = "transform_order_summary"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_order"; to = "load_sales_order_sqlserver"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_order"; to = "load_sales_order_postgres"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_line"; to = "load_sales_line_sqlserver"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_sales_line"; to = "load_sales_line_postgres"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_order_summary"; to = "load_order_summary_sqlserver"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "transform_order_summary"; to = "load_order_summary_postgres"; requirement = "artifact_available" }
                    [pscustomobject]@{ from = "load_sales_order_sqlserver"; to = "load_sales_line_sqlserver"; requirement = "required" }
                    [pscustomobject]@{ from = "load_sales_order_postgres"; to = "load_sales_line_postgres"; requirement = "required" }
                )
                SqlCopies = @(
                    [pscustomobject]@{ Source = "migrations/sqlserver/001_create_schema.sql"; Target = "sql/migrations/ss/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/005_create_sales.sql"; Target = "sql/migrations/ss/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "migrations/sqlserver/006_create_sales_summary.sql"; Target = "sql/migrations/ss/006_create_sales_summary.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/001_create_schema.sql"; Target = "sql/migrations/pg/001_create_schema.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/005_create_sales.sql"; Target = "sql/migrations/pg/005_create_sales.sql" }
                    [pscustomobject]@{ Source = "migrations/postgres/006_create_sales_summary.sql"; Target = "sql/migrations/pg/006_create_sales_summary.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/010_extract_sales_order.sql"; Target = "sql/steps/010_extract_sales_order.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/020_extract_sales_line.sql"; Target = "sql/steps/020_extract_sales_line.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/030_transform_sales_order.sql"; Target = "sql/steps/030_transform_sales_order.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/040_transform_sales_line.sql"; Target = "sql/steps/040_transform_sales_line.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/045_transform_order_summary.sql"; Target = "sql/steps/045_transform_order_summary.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/050_load_sales_order_sqlserver.sql"; Target = "sql/steps/050_load_sales_order_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/060_load_sales_order_postgres.sql"; Target = "sql/steps/060_load_sales_order_postgres.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/070_load_sales_line_sqlserver.sql"; Target = "sql/steps/070_load_sales_line_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/080_load_sales_line_postgres.sql"; Target = "sql/steps/080_load_sales_line_postgres.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/090_load_order_summary_sqlserver.sql"; Target = "sql/steps/090_load_order_summary_sqlserver.sql" }
                    [pscustomobject]@{ Source = "steps/E-artifacts/100_load_order_summary_postgres.sql"; Target = "sql/steps/100_load_order_summary_postgres.sql" }
                )
            }
        )
    }
}

function Build-PackageFromDefinition {
    param(
        [hashtable]$ScenarioDefinition,
        [string]$OutputRoot
    )

    $packageDir = Join-Path $OutputRoot $ScenarioDefinition.PackageDirectory
    Write-Info "Building package: $($ScenarioDefinition.PackageCode) -> $packageDir"
    New-CleanDirectory -Path $packageDir

    Write-ManifestYaml -PackageDir $packageDir -ScenarioDefinition $ScenarioDefinition
    Write-CatalogYaml -PackageDir $packageDir -ScenarioDefinition $ScenarioDefinition

    foreach ($pipeline in $ScenarioDefinition.Pipelines) {
        $pipelineDir = Join-Path $packageDir "pipelines/$($pipeline.Code)"
        Ensure-Directory -Path $pipelineDir

        foreach ($sqlMap in $pipeline.SqlCopies) {
            Copy-SqlFile -SourceRoot $sourceRoot -PipelineDir $pipelineDir -SourceRelativePath $sqlMap.Source -TargetRelativePath $sqlMap.Target
        }

        Write-PipelineYaml -PipelineDir $pipelineDir -PipelineDefinition $pipeline `
            -ConnectionNames @($ScenarioDefinition.Connections | ForEach-Object { [string]$_.name })
        Write-Utf8File -Path (Join-Path $pipelineDir "README.md") -Content $pipeline.Readme
    }

    if ($Validate) {
        Invoke-PackageValidation -PackageDir $packageDir -PackageCliAvailable:$packageCliAvailable -PackageCliProject $packageCliProject
    }

    if ($Zip) {
        $zipPath = Join-Path $OutputRoot "$($ScenarioDefinition.PackageDirectory).zip"
        Invoke-PackageZip -PackageDir $packageDir -ZipPath $zipPath -PackageCliAvailable:$packageCliAvailable -PackageCliProject $packageCliProject
    }

    return $packageDir
}

function New-CombinedScenarioDefinition {
    param(
        [string[]]$ScenarioKeys,
        [hashtable]$Definitions
    )

    $pipelines = [System.Collections.Generic.List[object]]::new()
    $pipelineCodes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $connectionsByName = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $scenarioLabels = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $ScenarioKeys) {
        $scenario = $Definitions[$key]
        if ($null -eq $scenario) {
            throw "Scenario definition missing for '$key'."
        }

        [void]$scenarioLabels.Add($key)

        foreach ($connection in $scenario.Connections) {
            $name = [string]$connection.name
            if ($connectionsByName.ContainsKey($name)) {
                $existing = $connectionsByName[$name]
                if (-not [string]::Equals([string]$existing.provider, [string]$connection.provider, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Combined package connection conflict for '$name': providers '$($existing.provider)' vs '$($connection.provider)'."
                }
                continue
            }

            $connectionsByName[$name] = $connection
        }

        foreach ($pipeline in $scenario.Pipelines) {
            $code = [string]$pipeline.Code
            if (-not $pipelineCodes.Add($code)) {
                throw "Combined package pipeline code collision: '$code'."
            }

            # Preserve per-scenario allow-list (pipeline connections) on each pipeline.
            $pipeline.ConnectionNames = @($scenario.Connections | ForEach-Object { [string]$_.name })
            $pipelines.Add($pipeline)
        }
    }

    if ($pipelines.Count -eq 0) {
        throw "Combined package requires at least one pipeline."
    }

    $labels = $scenarioLabels -join ", "
    return @{
        ScenarioCode = "ALL"
        PackageDirectory = "aw-lab-all"
        PackageCode = "aw-lab-all"
        PackageName = "AdventureWorks Lab (combined)"
        PackageDescription = "Combined AdventureWorks lab package for scenarios $labels."
        Revision = "phase6-lab-v1"
        Connections = @($connectionsByName.Values)
        Pipelines = @($pipelines)
    }
}

Ensure-Directory -Path $outputRoot
Write-Info "Selected scenarios: $($selectedScenarios -join ", ")"
Write-Info "Output root: $outputRoot"
if ($Combined) {
    Write-Info "Combined mode enabled: will also emit aw-lab-all"
}

foreach ($scenarioKey in $selectedScenarios) {
    $scenario = $scenarioDefinitions[$scenarioKey]
    if ($null -eq $scenario) {
        throw "Scenario definition missing for '$scenarioKey'."
    }

    [void](Build-PackageFromDefinition -ScenarioDefinition $scenario -OutputRoot $outputRoot)
}

if ($Combined) {
    $mergedScenario = New-CombinedScenarioDefinition -ScenarioKeys $selectedScenarios -Definitions $scenarioDefinitions
    [void](Build-PackageFromDefinition -ScenarioDefinition $mergedScenario -OutputRoot $outputRoot)
}

Write-Info "Done."
