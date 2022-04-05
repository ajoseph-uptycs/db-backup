#!/bin/bash


S3_BACKUP_PATH="s3://apj-db-backup/db-backup"



stop_psql_containers() {

	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down
	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down
	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down

}

add_recovery_configuration_to_configdb() {

printf "Adding recovery Configuration to configdb/postgresql.conf"
cat <<EOT >> /opt/uptycs/etc/postgres/configdb/postgresql.conf
----------------------- RECOVERY CONFIGS -----------------------
restore_command = 'cp /warehouse/db-restore/configdb/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
touch /pg/configdb/main/recovery.signal
EOT

}


copy_s3_contents_to_configdb() {

	if [ -z "$S3_BACKUP_PATH" ]
	then
		printf "S3_BACKUP_PATH is not set \n"
		return 1 
	fi

	mv /pg/configdb/main /pg/configdb/main-bk
	mv /data/pgdata/configdb /data/pgdata/configdb-bk
	mkdir -p /data/pgdata/configdb/PG_13_202007201
	mkdir -p /warehouse/db-restore/

	aws s3 sync $S3_BACKUP_PATH/configdb/basebackup/* /pg/configdb/main/
	aws s3 sync $S3_BACKUP_PATH/configdb/pg_tblspc-24576/* /data/pgdata/configdb/PG_13_202007201
	ln -s /data/pgdata/configdb/PG_13_202007201 /pg/configdb/main/pg_tblspc/24576
	aws s3 sync $S3_BACKUP_PATH/configdb/basebackup-pg_wal/* /pg/configdb/main/pg_wal/
	aws s3 sync $S3_BACKUP_PATH/configdb/walfiles_archive /warehouse/db-restore/configdb/

	chown -R monkey:monkey /data/pgdata /warehouse/db-restore /pg/configdb

}



add_recovery_configuration_to_metastoredb() {

printf "Adding recovery Configuration to metastoredb/postgresql.conf"
cat <<EOT >> /opt/uptycs/etc/postgres/metastoredb/postgresql.conf
----------------------- RECOVERY CONFIGS -----------------------

restore_command = 'cp /warehouse/db-restore/metastoredb/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
touch /pg/metastoredb/main/recovery.signal
EOT

}


copy_s3_contents_to_metastoredb() {

	if [ -z "$S3_BACKUP_PATH" ]
	then
		printf "S3_BACKUP_PATH is not set \n"
		return 1 
	fi

	mv /pg/metastoredb/main /pg/metastoredb/main-bk
	mv /data/pgdata/metastoredb /data/pgdata/metastoredb-bk
	mkdir -p /data/pgdata/metastoredb/PG_13_202007201
	mkdir -p /warehouse/db-restore/

	aws s3 sync $S3_BACKUP_PATH/metastoredb/basebackup/* /pg/metastoredb/main/
	aws s3 sync $S3_BACKUP_PATH/metastoredb/pg_tblspc-24576/* /data/pgdata/metastoredb/PG_13_202007201
	ln -s /data/pgdata/metastoredb/PG_13_202007201 /pg/metastoredb/main/pg_tblspc/24576
	aws s3 sync $S3_BACKUP_PATH/metastoredb/basebackup-pg_wal/* /pg/metastoredb/main/pg_wal/
	aws s3 sync $S3_BACKUP_PATH/metastoredb/walfiles_archive /warehouse/db-restore/metastoredb/

	chown -R monkey:monkey /data/pgdata /warehouse/db-restore /pg/metastoredb

}



add_recovery_configuration_to_statedb() {

printf "Adding recovery Configuration to statedb/postgresql.conf"
cat <<EOT >> /opt/uptycs/etc/postgres/statedb/postgresql.conf
----------------------- RECOVERY CONFIGS -----------------------

restore_command = 'cp /warehouse/db-restore/statedb/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
touch /pg/statedb/main/recovery.signal
EOT

}


copy_s3_contents_to_statedb() {

	if [ -z "$S3_BACKUP_PATH" ]
	then
		printf "S3_BACKUP_PATH is not set \n"
		return 1 
	fi

	mv /pg/statedb/main /pg/statedb/main-bk
	mv /data/pgdata/statedb /data/pgdata/statedb-bk
	mkdir -p /data/pgdata/statedb/PG_13_202007201
	mkdir -p /warehouse/db-restore/

	aws s3 sync $S3_BACKUP_PATH/statedb/basebackup/* /pg/statedb/main/
	aws s3 sync $S3_BACKUP_PATH/statedb/pg_tblspc-24576/* /data/pgdata/statedb/PG_13_202007201
	ln -s /data/pgdata/statedb/PG_13_202007201 /pg/statedb/main/pg_tblspc/24576
	aws s3 sync $S3_BACKUP_PATH/statedb/basebackup-pg_wal/* /pg/statedb/main/pg_wal/
	aws s3 sync $S3_BACKUP_PATH/statedb/walfiles_archive /warehouse/db-restore/statedb/

	chown -R monkey:monkey /data/pgdata /warehouse/db-restore /pg/statedb

}


start_configdb() {

	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml up -d

}

start_metastoredb() {

	docker-compose -f /opt/uptycs/etc/postgres/metastoredb/docker-compose.yml up -d

}

start_statedb() {

	docker-compose -f /opt/uptycs/etc/postgres/statedb/docker-compose.yml up -d

}

stop_psql_containers

add_recovery_configuration_to_configdb
add_recovery_configuration_to_metastoredb
add_recovery_configuration_to_statedb

copy_s3_contents_to_configdb
copy_s3_contents_to_metastoredb
copy_s3_contents_to_statedb