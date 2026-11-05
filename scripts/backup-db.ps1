param(
    [string]$Server = "localhost\SQLEXPRESS",
    [string]$Database = "FOMS_DB",
    [string]$BackupDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $BackupDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDir = Split-Path -Parent $scriptDir
    $BackupDir = Join-Path $rootDir "backups"
}

if ($Database -notmatch '^[A-Za-z0-9_]+$') {
    throw "Database name must contain only letters, digits, and underscores."
}

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$backupFile = Join-Path $BackupDir "${Database}_backup_${timestamp}.bak"
$resolvedPath = [System.IO.Path]::GetFullPath($backupFile)

Write-Host "Backing up database [$Database] from [$Server] to [$resolvedPath]..." -ForegroundColor Cyan

if (Test-Path $resolvedPath) {
    throw "Refusing to overwrite an existing backup: $resolvedPath"
}

$escapedPath = $resolvedPath.Replace("'", "''")
$backupQuery = "BACKUP DATABASE [$Database] TO DISK = N'$escapedPath' WITH INIT, STATS = 10"
& sqlcmd -S $Server -E -C -Q $backupQuery

if ($LASTEXITCODE -ne 0) {
    Write-Error "Backup failed with exit code $LASTEXITCODE"
}

if (Test-Path $resolvedPath) {
    $fileInfo = Get-Item $resolvedPath
    Write-Host "SUCCESS: Backup completed successfully!" -ForegroundColor Green
    Write-Host "File Path: $($fileInfo.FullName)" -ForegroundColor Green
    Write-Host "File Size: $($fileInfo.Length) bytes ($([math]::Round($fileInfo.Length / 1MB, 2)) MB)" -ForegroundColor Green
    return $fileInfo.FullName
} else {
    Write-Error "Backup file was not found at $resolvedPath"
}
