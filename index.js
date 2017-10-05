const cron = require('node-cron')
const Logger = require('le_node')
const fs = require('fs');
const {exec} = require('child_process');
const formatter = require('dateformat')

const CRON_TIME = process.env.CRON_TIME
const MAX_BACKUPS = process.env.MAX_BACKUPS
const BACKUP_DIR = "./backup"
const DB_URL = `postgres://${process.env.DB_USER}:${process.env.DB_PASS}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`

var logger = new Logger(
    {
        token: process.env.LE_TOKEN
    });
console.log(CRON_TIME)
cron.schedule(CRON_TIME, async () => {
    await clearDir()
    await runPgDump()
});

async function runPgDump() {
    var formattedDate = formatter(new Date(), "dd-mm-yyyy_HH_MM_ss")
    exec(
        `pg_dump -c ${DB_URL}`, {maxBuffer: 1024 * 1024 * 256}, // 256 MB
        function (err, data) {
            if (err) {
                console.log(`Backup failed at ${formattedDate}`)
                console.log(err)
                logger.err(`${formattedDate} MAINTENANCE - database backup failed.`)
            } else {
                fs.writeFile(`${BACKUP_DIR}/dump_${formattedDate}.sql`, data, err => {
                    if (err) {
                        console.log(`Backup failed at ${formattedDate}`)
                        console.log(err)
                        logger.err(`${formattedDate} MAINTENANCE - database backup failed.`)
                    } else {
                        logger.info(`${formattedDate} MAINTENANCE - database backup succeeded. FILE=${BACKUP_DIR}/dump_${formattedDate}.sql`)
                        console.log(`Backup succeeded at ${formattedDate}`)
                    }
                })
            }
        }
    );
}

async function clearDir() {
    var files = await fs.readdirAsync(BACKUP_DIR)
    if (files.length >= MAX_BACKUPS) {
        fs.unlink(`${BACKUP_DIR}/${files[0]}`, (err) => {
            console.log(err)
        })
        await clearDir()
    }
}