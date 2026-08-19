# AdventureWorks lab source

Canonical SQL and the packing script for the Querial AdventureWorks labs.

```powershell
.\build-packages.ps1
.\build-packages.ps1 -Validate
.\build-packages.ps1 -Zip -Validate
.\build-packages.ps1 -Scenarios A,C
.\build-packages.ps1 -Combined -Zip
.\verify-connections.ps1
```

Output lands in `packages/` next to this script. Import the resulting zip in Workspace: **Pipelines → Import package**.

See the Labs pages on this site for scenario topology, roles, and how to publish, deploy, run, and inspect the graph.
