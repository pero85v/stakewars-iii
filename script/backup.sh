#!/bin/bash

DATE=$(date +%Y-%m-%d-%H-%M)
DATADIR=/home/pero/.near
BACKUPDIR=/home/pero/backups/near_${DATE}

mkdir $BACKUPDIR

sudo systemctl stop neard

wait

echo "NEAR node was stopped" | ts

if [ -d "$BACKUPDIR" ]; then
    echo "Backup started" | ts

    cp -rf $DATADIR/data/ ${BACKUPDIR}/

    # Submit message to email
    curl --data-urlencode "topicName=XX" --data-urlencode "message=Backup near_${DATE} completed" --data-urlencode "subject=Backup" -H "Authorization: Bearer XX" -X POST http://localhost:8080/broadcastMessage

    echo "Backup completed" | ts
else
    sudo systemctl start neard
    echo $BACKUPDIR is not created. Check your permissions.
    exit 0
fi

sudo systemctl start neard

echo "NEAR node was started" | ts
