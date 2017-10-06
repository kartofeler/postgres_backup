#!/bin/bash
#[ -z "${POSTGRES_HOST}" ] && { echo "=> POSTGRES_HOST cannot be empty" && exit 1; }
#[ -z "${POSTGRES_PORT}" ] && { echo "=> POSTGRES_PORT cannot be empty" && exit 1; }
#[ -z "${POSTGRES_USER}" ] && { echo "=> POSTGRES_USER cannot be empty" && exit 1; }
#[ -z "${POSTGRES_PASSWORD}" ] && { echo "=> POSTGRES_PASSWORD cannot be empty" && exit 1; }
#[ -z "${POSTGRES_DB}" ] && { echo "=> POSTGRES_DB cannot be empty" && exit 1; }

export PGPASSWORD="${POSTGRES_PASSWORD}"

BACKUP_CMD="pg_dump -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} ${POSTGRES_DB} > /backup/\${BACKUP_NAME} 2> /_failed/failed_\${BACKUP_NAME}.log"

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash
MAX_BACKUPS=${MAX_BACKUPS}
SLACK=${SLACK_WEBHOOK}
BACKUP_NAME=dump_\$(date +%d-%m-%Y_%H_%M_%S).sql
export PGPASSWORD="${POSTGRES_PASSWORD}"
echo "=> Backup started: \${BACKUP_NAME}"
if ${BACKUP_CMD} ;then
    echo "   Backup succeeded"
    if [ -n "\${SLACK}" ]; then
      curl -s -X POST --data-urlencode "payload={\"username\": \"Backup BOT\", \"text\": \"*HA MAINTENANCE* - database backup succeded: file=*\${BACKUP_NAME}*\"}" \${SLACK}
    fi
else
    echo "   Backup failed"
    if [ -n "\${SLACK}" ]; then
      curl -s -X POST --data-urlencode "payload={\"username\": \"Backup BOT\", \"text\": \"*HA MAINTENANCE* - database backup failed\"}" \${SLACK}
    fi
fi
if [ -n "\${MAX_BACKUPS}" ]; then
    while [ \$(ls /backup | wc -l) -gt \${MAX_BACKUPS} ];
    do
        BACKUP_TO_BE_DELETED=\$(ls /backup | sort | head -n 1)
        echo "   Backup \${BACKUP_TO_BE_DELETED} is deleted"
        rm -rf /backup/\${BACKUP_TO_BE_DELETED}
    done
fi
echo "=> Backup done"
EOF
chmod +x /backup.sh


touch /postgres_backup.log
tail -F /postgres_backup.log &


echo "${CRON_TIME} /backup.sh >> /postgres_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec crond -f