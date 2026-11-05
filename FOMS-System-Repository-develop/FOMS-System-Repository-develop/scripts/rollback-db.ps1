param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$TargetDatabase = "FOMS_DB_RESTORE_TEST",
    [string]$Server = "localhost\SQLEXPRESS"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BackupFile)) {
    Write-Error "Backup file not found at: $BackupFile"
}

$resolvedBackupPath = [System.IO.Path]::GetFullPath($BackupFile)

if ($TargetDatabase -notmatch '^[A-Za-z0-9_]+$') {
    throw "Target database must contain only letters, digits, and underscores."
}

if ($TargetDatabase.Equals("FOMS_DB", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "SAFETY GUARD BLOCKED: Restoring to the live database FOMS_DB is permanently disabled in this script."
}

Write-Host "Restoring backup [$resolvedBackupPath] to [$TargetDatabase] on [$Server]..." -ForegroundColor Yellow
$escapedBackupPath = $resolvedBackupPath.Replace("'", "''")

$sql = @"
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$TargetDatabase')
BEGIN
    ALTER DATABASE [$TargetDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END

RESTORE DATABASE [$TargetDatabase] FROM DISK = N'$escapedBackupPath'
WITH REPLACE, RECOVERY, STATS = 10;

ALTER DATABASE [$TargetDatabase] SET MULTI_USER;
"@

& sqlcmd -S $Server -E -C -Q $sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Database [$TargetDatabase] successfully restored from [$resolvedBackupPath]." -ForegroundColor Green
} else {
    Write-Error "Restore operation failed with exit code $LASTEXITCODE."
}
