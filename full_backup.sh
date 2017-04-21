#!/bin/bash
#The user doing the backup, needs access to all the files!
BUSER = backup-bot
#Location of the local backup
BLOCATION = /backup
#Name of the backup
OF=$(date +%Y%m%d%h%m)-d-server
#Number of backups to keep (= how old should the oldest be if run once each day)
MAXAGE=7

echo "Starting full system backup..."

#The motherload....
rsync -aAXvHS --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found",$BLOCATION} / $BLOCATION/$OF

#Compress the backup
tar -zcf $OF.tgz $OF

#Remove the non-compressed folder
rm -rf $BLOCATION/$OF

#Remove backups older than MAXAGE
find $BLOCATION -mtime +$MAXAGE -type f #-delete <-- Add this after testing!

#Chmod-things

