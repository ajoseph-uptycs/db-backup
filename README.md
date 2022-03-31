# db-backup
Database Backup using pg_basebackup And WAL files Archiving


COMMON archive_command (common location)
	-     - "archive_command = 'test ! -f /pg/backup/walfiles_archive/%f && cp %p /pg/backup/walfiles_archive/%f'"



Docker volumes:
      - "/opt/uptycs/etc/postgres/configdb:/opt/postgres/pg"
      - /data/pgdata/configdb:/data/pgdata/configdb
      - /pg/configdb:/pg
      - /pg/configdb/backup:/pg/backup
      - /opt/uptycs/var/log/postgresql/configdb:/var/log/postgresql


#      - /warehouse/db-backup/configdb/walfiles:/pg/backup/walfiles



Common BACKUP_PATH in Host system: /warehouse/db-backup

Backup Directory Structure in Host System: ( To avoid any modifications to existing docker-compose.yml )


/warehouse/db-backup/configdb
                          - basebackup
                          - walfiles_archive	# symlink from /pg/configdb/backup/<DB-NAME>/walfiles_archive
/warehouse/db-backup/metastoredb
                          - basebackup
                          - walfiles_archive	# symlink from /pg/configdb/backup/<DB-NAME>/walfiles_archive
/warehouse/db-backup/statedb
                          - basebackup
                          - walfiles_archive	# symlink from /pg/configdb/backup/<DB-NAME>/walfiles_archive



Old Requirement:
	- <db-name>/docker-compose.yml have /warehouse/db-backup as a mount point
			- /warehouse/db-backup:/warehouse/db-backup
/pg/configdb/backup

  shell: >
      ln -s /pg/configdb/backup/walfiles-archive  "{{ backup_path }}"/configdb/walfiles_archive
      ln -s /pg/metastoredb/backup/walfiles-archive  "{{ backup_path }}"/metastoredb/walfiles_archive
      ln -s /pg/statedb/backup/walfiles-archive  "{{ backup_path }}"/statedb/walfiles_archive




aws s3 --recursive mv {{ s3_db_backup_url }}/* {{ s3_db_backup_url }}/db-backup-$datevar


datevar=$(date +'%Y-%m-%d-%H-%M')
aws s3 --recursive mv s3://apj-db-backup/* s3://apj-db-backup/db-backup-datevar/
