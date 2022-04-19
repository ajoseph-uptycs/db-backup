#!/bin/bash


S3_BACKUP_URL="s3://apj-db-backup/db-backup"
BACKUP_PATH="/warehouse/db-restore"

copy_backup_fromS3() {

	aws s3 sync s3://apj-db-backup/db-backup /warehouse/db-restore
	if [ $? -eq 0 ]; then
		echo "S3 Contents Synced to /warehouse successfully\n\n"
	else
		echo "\nS3 Sync failed"
		return 1
	fi	
}

clean_db_directories() {

	mkdir ~/db-directories-orig
	mv /pg/* ~/db-directories-orig/
	mv /data/pgdata ~/db-directories-orig/
}

stop_psql_containers() {

	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down
	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down
	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml down

}

add_recovery_configuration_to_configdb() {

printf "\nAdding recovery Configuration to configdb/postgresql.conf \n "
cat <<EOT >> /opt/uptycs/etc/postgres/configdb/postgresql.conf
#----------------------- RECOVERY CONFIGS -----------------------
restore_command = 'cp /warehouse/db-restore/configdb/walfiles_archive/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
EOT

touch /pg/configdb/main/recovery.signal
rm /pg/statedb/main/standby.signal

}


copy_s3_contents_to_configdb() {

	if [ -z "$BACKUP_PATH" ]
	then
		printf "BACKUP_PATH is not set \n"
		return 1 
	fi

	printf "\nCopying copy_s3_contents_to_configdb\n"

	mkdir -p /data/pgdata/configdb/PG_13_202007201
	mkdir -p /warehouse/db-restore/
	mkdir -p /pg/configdb/main/pg_tblspc /data/pgdata/configdb 

	cp -r $BACKUP_PATH/configdb/basebackup/* /pg/configdb/main/
	cp -r $BACKUP_PATH/configdb/pg_tblspc-24576/* /data/pgdata/configdb/PG_13_202007201
	#ln -s /data/pgdata/configdb/PG_13_202007201 /pg/configdb/main/pg_tblspc/24576
	cp -r $BACKUP_PATH/configdb/basebackup-pg_wal/* /pg/configdb/main/pg_wal/
	rm -f /pg/configdb/main/postgresql.auto.conf
	printf "\nCopied Contents to configdb data-directories\n"

}



add_recovery_configuration_to_metastoredb() {

printf "\nAdding recovery Configuration to metastoredb/postgresql.conf..\n "
cat <<EOT >> /opt/uptycs/etc/postgres/metastoredb/postgresql.conf
#----------------------- RECOVERY CONFIGS -----------------------

restore_command = 'cp /warehouse/db-restore/metastoredb/walfiles_archive/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
EOT

touch /pg/metastoredb/main/recovery.signal
rm /pg/metastoredb/main/standby.signal


}


copy_s3_contents_to_metastoredb() {

	if [ -z "$BACKUP_PATH" ]
	then
		printf "BACKUP_PATH is not set \n"
		return 1 
	fi

	printf "\nCopying copy_s3_contents_to_metastoredb \n"

	mkdir -p /data/pgdata/metastoredb/PG_13_202007201
	mkdir -p /warehouse/db-restore/
	mkdir -p /pg/metastoredb/main/pg_tblspc /data/pgdata/metastoredb

	cp -r $BACKUP_PATH/metastoredb/basebackup/* /pg/metastoredb/main/
	cp -r $BACKUP_PATH/metastoredb/pg_tblspc-24576/* /data/pgdata/metastoredb/PG_13_202007201
	#ln -s /data/pgdata/metastoredb/PG_13_202007201 /pg/metastoredb/main/pg_tblspc/24576
	cp -r $BACKUP_PATH/metastoredb/basebackup-pg_wal/* /pg/metastoredb/main/pg_wal/
	rm -f /pg/metastoredb/main/postgresql.auto.conf
	printf "\nCopied Contents to configdb data-directories\n"

}



add_recovery_configuration_to_statedb() {

printf "\n Adding recovery Configuration to statedb/postgresql.conf \n\n"
cat <<EOT >> /opt/uptycs/etc/postgres/statedb/postgresql.conf
#----------------------- RECOVERY CONFIGS -----------------------

restore_command = 'cp /warehouse/db-restore/statedb/walfiles_archive/%f "%p"'
recovery_target_timeline = 'latest'
recovery_target_action = promote
EOT

touch /pg/statedb/main/recovery.signal
rm /pg/statedb/main/standby.signal


}


copy_s3_contents_to_statedb() {

	if [ -z "$BACKUP_PATH" ]
	then
		printf "BACKUP_PATH is not set \n"
		return 1 
	fi

	printf "\n\n Copying copy_s3_contents_to_statedb \n\n"

	mkdir -p /data/pgdata/statedb/PG_13_202007201
	mkdir -p /warehouse/db-restore/
	mkdir -p /pg/statedb/main/pg_tblspc /data/pgdata/statedb

	cp -r $BACKUP_PATH/statedb/basebackup/* /pg/statedb/main/
	cp -r $BACKUP_PATH/statedb/pg_tblspc-24576/* /data/pgdata/statedb/PG_13_202007201
	#ln -s /data/pgdata/statedb/PG_13_202007201 /pg/statedb/main/pg_tblspc/24576
	cp -r $BACKUP_PATH/statedb/basebackup-pg_wal/* /pg/statedb/main/pg_wal/
	rm -f /pg/metastoredb/main/postgresql.auto.conf
	printf "\nCopied Contents to configdb data-directories\n"

}


correct_permissions() {

	printf "\nCorrecting Permissions/Ownership of directories..\n"
	chown -R monkey:monkey /data/pgdata /warehouse/db-restore /pg/
	chmod -R 0750 /data/pgdata /warehouse/db-restore /pg/
}



start_configdb() {

	printf "Starting ConfigDB container.."
	docker-compose -f /opt/uptycs/etc/postgres/configdb/docker-compose.yml up -d

}

start_metastoredb() {

	printf "\nStarting MetastoreDB container.."
	docker-compose -f /opt/uptycs/etc/postgres/metastoredb/docker-compose.yml up -d

}

start_statedb() {

	printf "\nStarting StateDB container.."
	docker-compose -f /opt/uptycs/etc/postgres/statedb/docker-compose.yml up -d

}

start_pgbouncers(){

	docker-compose -f /opt/uptycs/etc/pgbouncer/docker-compose.yml up -d
	docker-compose -f /opt/uptycs/etc/pgbouncer/configdb/docker-compose.yml up -d
}

stop_psql_containers
#clean_db_directories
#copy_backup_fromS3

copy_s3_contents_to_configdb
copy_s3_contents_to_metastoredb
copy_s3_contents_to_statedb

add_recovery_configuration_to_configdb
add_recovery_configuration_to_metastoredb
add_recovery_configuration_to_statedb

correct_permissions

#start_configdb
#start_metastoredb
#start_statedb
#start_pgbouncers