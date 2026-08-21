# Verify local AdventureWorks lab connections
#
# Does not apply Querial migrations (leave that to the pipeline).
# Requires: Docker (Aspire target-pg running), sqlcmd, Windows auth to SQL Server.
#
# Example:
#   .\verify-connections.ps1
#   .\verify-connections.ps1 -AdventureWorksDb AdventureWorks2022 -QuerialSqlDb QuerialAdventureWorks

[CmdletBinding()]
param(
    [string] $SqlServerInstance = ".",
    [string] $AdventureWorksDb = "AdventureWorks",
    [string] $QuerialSqlDb = "QuerialAdventureWorks",
    [string] $PgHost = "127.0.0.1",
    [int] $PgPort = 15434,
    [string] $PgDatabase = "querial_test",
    [string] $PgUser = "postgres",
    [string] $PgPassword = "1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Check([bool] $ok, [string] $message) {
    if ($ok) {
        Write-Host "  OK  $message" -ForegroundColor Green
    }
    else {
        Write-Host "  FAIL $message" -ForegroundColor Red
    }
}

$failed = 0

Write-Host "SQL Server ($SqlServerInstance)" -ForegroundColor Cyan

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if ($null -eq $sqlcmd) {
    Write-Check $false "sqlcmd is not on PATH. Install SQL Server Command Line Tools or skip this check."
    $failed++
}
else {
    $awCount = sqlcmd -S $SqlServerInstance -E -C -d $AdventureWorksDb -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM Person.Person;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Check $true "AdventureWorks catalog '$AdventureWorksDb' (Person.Person rows: $($awCount.ToString().Trim()))"
    }
    else {
        Write-Check $false "Cannot query '$AdventureWorksDb'. $($awCount | Out-String)"
        $failed++
    }

    $destPing = sqlcmd -S $SqlServerInstance -E -C -d $QuerialSqlDb -h -1 -W -Q "SET NOCOUNT ON; SELECT DB_NAME();" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Check $true "Querial SQL destination catalog '$QuerialSqlDb'"
    }
    else {
        Write-Check $false "Cannot open '$QuerialSqlDb'. Create it or pass -QuerialSqlDb. $($destPing | Out-String)"
        $failed++
    }
}

Write-Host "PostgreSQL target ($PgHost`:$PgPort / $PgDatabase)" -ForegroundColor Cyan

$cid = docker ps --filter "name=target-pg" --format "{{.ID}}" 2>&1 | Select-Object -First 1
if (-not $cid) {
    Write-Check $false "No running container matching name 'target-pg'. Start Aspire AppHost first."
    $failed++
}
else {
    $pgOut = docker exec -e "PGPASSWORD=$PgPassword" $cid psql -U $PgUser -d $PgDatabase -tAc "SELECT current_database() || ' as ' || current_user;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Check $true "querial_test reachable ($($pgOut.ToString().Trim()))"
    }
    else {
        Write-Check $false "psql inside target-pg failed. $($pgOut | Out-String)"
        $failed++
    }
}

Write-Host "Host TCP $PgHost`:$PgPort (Querial connection string uses this)" -ForegroundColor Cyan
try {
    $tcp = Test-NetConnection -ComputerName $PgHost -Port $PgPort -WarningAction SilentlyContinue
    Write-Check $tcp.TcpTestSucceeded "Port $PgPort is open on $PgHost"
    if (-not $tcp.TcpTestSucceeded) { $failed++ }
}
catch {
    Write-Check $false $_.Exception.Message
    $failed++
}

if ($failed -gt 0) {
    Write-Host "`n$failed check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nAll checks passed. Next: lab/adventureworks/README.md" -ForegroundColor Green
