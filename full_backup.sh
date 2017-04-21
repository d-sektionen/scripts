#!/bin/bash
#The user doing the backup, needs access to all the files!
BUSER="backup-bot"
#Location of the local backup
BLOCATION="/backup"
#Name of the backup
OF=$(date +%Y%m%d%H%M)_d-server
#Number of backups to keep (= how old should the oldest be if run once each day)
MAXAGE=7

echo "Starting full system backup..."
mkdir $BLOCATION/$OF

if [ ! -d "$BLOCATION/$OF" ]; then
	echo "Problem creating the backup folder $BLOCATION/$OF, exiting..."
	exit
fi
echo "Backuplocation $BLOCATION/$OF created"
#The motherload....
echo "Starting rsync..."
rsync -aAXvHS --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$BLOCATION/*"} / $BLOCATION/$OF
echo "rsync done! Tar is next..."
#Compress the backup
tar -zcf $BLOCATION/$OF.tgz $BLOCATION/$OF
echo "Compressed and ready"
#Remove the non-compressed folder
rm -rf $BLOCATION/$OF

#Remove backups older than MAXAGE
find $BLOCATION -mtime +$MAXAGE -type f -delete

#Chmod-things
chown backup-bot:admins $BLOCATION/$OF.tgz
