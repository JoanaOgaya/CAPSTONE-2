# FOMS Database Backup and Rollback Runbook

This runbook defines database safety operations for the Speedex Finance Operations Management System (FOMS).

---

## 1. Safety Rules

1. **Safety First**: Every schema modification or data migration step MUST be preceded by a verified database backup.
2. **Never Run Rollback on Live Database**: The rollback script defaults to the isolated verification database `FOMS_DB_RESTORE_TEST` and permanently refuses the live database name `FOMS_DB`. Do not bypass or replace this guard.
3. **Immutability of Backups**: Timestamped `.bak` files are append-only snapshots. Never overwrite previous backups.

---

## 2. Phase 1 Baseline Backup Artifact

| Property | Value |
|---|---|
| **Database Name** | `FOMS_DB` |
| **Instance** | `localhost\SQLEXPRESS` (Server: `joo\SQLEXPRESS`) |
| **Backup Timestamp** | `2026-11-05 19:07:40.826 (local time)` |
| **Backup File Path** | `C:\Users\Joana\Downloads\EWAN NA SES\backups\FOMS_DB_backup_20261105_190740_826.bak` |
| **Relative Path** | `backups/FOMS_DB_backup_20261105_190740_826.bak` |
| **File Size** | `14,602,240 bytes (13.93 MB)` |
| **SHA256 Checksum** | `07BB938B6DEA94E4C48F3FF15155DA95617815BF7B0AB0145E7501173EF5860D` |
| **Backup Verification** | `RESTORE VERIFYONLY` passed; no database restore performed |

---

## 3. Database Backup Procedure

### Script Location
- Bash/sh: `scripts/backup-db`
- PowerShell: `scripts/backup-db.ps1`

### Usage (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/backup-db.ps1
```

### Optional Parameters
```powershell
powershell -ExecutionPolicy Bypass -File scripts/backup-db.ps1 -Server "localhost\SQLEXPRESS" -Database "FOMS_DB" -BackupDir "backups"
```

### Usage (Bash)
```bash
./scripts/backup-db "localhost\\SQLEXPRESS" "FOMS_DB" "backups"
```

The PowerShell script:
1. Validates or creates the target backup directory.
2. Uses a timestamp including milliseconds and refuses to overwrite an existing backup file.
3. Executes `BACKUP DATABASE [FOMS_DB] TO DISK = '<path>' WITH INIT, STATS = 10`.
4. Reports the exact path and size. The SQL Server service account must already have write access; the script does not grant broad directory permissions.

---

## 4. Rollback / Restore Procedure

### Script Location
- Bash/sh: `scripts/rollback-db`
- PowerShell: `scripts/rollback-db.ps1`

### Safe Verification Restore
To restore a chosen snapshot into the isolated verification database (never the live database):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/rollback-db.ps1 `
    -BackupFile "backups\FOMS_DB_backup_20261105_190740_826.bak" `
    -TargetDatabase "FOMS_DB_RESTORE_TEST"
```

Or using Bash:
```bash
./scripts/rollback-db "backups/FOMS_DB_backup_20261105_190740_826.bak" "FOMS_DB_RESTORE_TEST"
```

The rollback scripts validate the target database identifier and block `FOMS_DB` unconditionally. No rollback was executed during Phase 1; only `RESTORE VERIFYONLY` was used to verify the backup set.
