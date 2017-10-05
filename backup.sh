#!/bin/bash
MAX_BACKUPS=
BACKUP_NAME=$(date +\%Y.\%m.\%d.\%H\%M\%S).sql
export PGPASSWORD="symfony22#"
echo "=> Backup started: ${BACKUP_NAME}"
if pg_dump -h localhost# -p 5433# -U symfony33# -f ./backup/${BACKUP_NAME} planszolo_dev ;then
    echo "   Backup succeeded"
else
    echo "   Backup failed"
    rm -rf /backup/${BACKUP_NAME}
fi
if [ -n "${MAX_BACKUPS}" ]; then
    while [ $(ls /backup -N1 | wc -l) -gt ${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=$(ls /backup -N1 | sort | head -n 1)
        echo "   Backup ${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup done"
