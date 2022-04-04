#Requirement : A Working Fresh 3 SU Stack
https://www.postgresql.org/docs/13/continuous-archiving.html


- backup configuration files if required postgresql.conf & pb_hba.conf
- backup pg_wal (in case if it is not archived) 
		- This can be move to restoring node (pg_wal). If archive don't have any WAL, it will be looked in this location. (but preference to archive/WAL-files)

- archive_timeout
- pg_switch_wal	# https://www.postgresql.org/docs/13/functions-admin.html#FUNCTIONS-ADMIN-BACKUP-TABLE

- OPTN:
	- recovery_target_name:	named restore point    
			- created using: pg_create_restore_point()

- PAUSE:
```
		- archive_command='' 		# pg_wal will be accumulated.
		- reload configuration
```


- Make sure below files are not present  ( these can confuse pg_ctl )
	- postmaster.pid and postmaster.opts


```
- Optional: contents of the directories (directories are required)
		- pg_dynshmem
		- pg_notify
		- pg_serial
		- pg_snapshots
		- pg_stat_tmp
		- pg_subtrans

		- Any file or directory beginning with pgsql_tmp can be omitted from the backup.
```

- verify that the symbolic links in pg_tblspc/ were correctly restored.

Recovery configuration Settings
	- https://www.postgresql.org/docs/13/runtime-config-wal.html#RUNTIME-CONFIG-WAL-ARCHIVE-RECOVERY

```
restore_command = 'cp /mnt/server/archivedir/%f %p'
restore_command = 'cp /mnt/server/archivedir/%f "%p"'
recovery_target_time
recovery_target_action = pause/promote/shutdown
```

archive_cleanup_command = 'pg_archivecleanup /path/to/archive %r'


- Create recovery.signal in cluster data dir.    # not removed if target_action=shutdown
- modify pg_hba.conf to prevent ordinary users from connecting until recovery is completed.
- start server


```
Normally, recovery will proceed through all available WAL segments, thereby restoring the database to the current point in time (or as close as possible given the available WAL segments). Therefore, a normal recovery will end with a “file not found” message, the exact text of the error message depending upon your choice of restore_command. You may also see an error message at the start of recovery for a file named something like 00000001.history. This is also normal and does not indicate a problem in simple recovery situations; see Section 25.3.5 for discussion.
```
https://www.postgresql.org/docs/13/continuous-archiving.html#BACKUP-TIMELINES

- Timelines (not required atm) 
		- https://www.postgresql.org/docs/13/functions-admin.html#FUNCTIONS-ADMIN-BACKUP-TABLE
		- pg_create_restore_point ( name text ) , recovery_target_name


```
postgres=# SELECT * FROM pg_walfile_name_offset(pg_stop_backup());
        file_name         | file_offset
--------------------------+-------------
 00000001000000000000000D |     4039624
(1 row)
```


- pg_is_in_recovery ()		# Check status of recovery True -> still in progress



STANDBY
```
	- standby.signal
	- primary_conninfo
archive_cleanup_command = 'pg_archivecleanup /mnt/server/archivedir %r'

max_wal_senders
```