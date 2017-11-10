#!/bin/bash
#The user doing the backup, needs access to all the files!
BUSER="backup-bot:admins"
#Location of the local backup
BLOCATION="/backup"
#Name of the backup
OF=$(date +%Y%m%d%H%M)_d-server
#Number of backups to keep (= how old should the oldest be if run once each day)
MAXAGE=10
#Log file location
LOG="var/log/backup.log"

#Output STDOUT & STDERR both to log-file and terminal
exec > >(tee -ia /var/log/backup.log)
exec 2> >(tee -ia /var/log/backup.log)

echo "[$(date +%Y-%m-%d,%H:%M)] ####Starting full system backup####"
echo "[$(date +%Y-%m-%d,%H:%M)] Mounting /dev/vda1 to $BACKUP..."

if grep -qs "$BLOCATION" /proc/mounts; then
  echo "[$(date +%Y-%m-%d,%H:%M)] It's already mounted."
else
  mount "$mount"
  if [ $? -eq 0 ]; then
   echo "[$(date +%Y-%m-%d,%H:%M)] Mounted!"
  else
   echo "[$(date +%Y-%m-%d,%H:%M)] Something went wrong with the mount, exiting"
   exit
  fi
fi

mkdir $BLOCATION/$OF

if [ ! -d "$BLOCATION/$OF" ]; then
	echo "[$(date +%Y-%m-%d,%H:%M)] Problem creating the backup folder $BLOCATION/$OF, exiting..."
	exit
fi
echo "[$(date +%Y-%m-%d,%H:%M)] Backuplocation $BLOCATION/$OF created"
#The motherload....
echo "[$(date +%Y-%m-%d,%H:%M)] Starting rsync..."
rsync -aAXvHSq --exclude={"/var/cache/*","/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$BLOCATION/*"} / $BLOCATION/$OF
#For testing
#touch $BLOCATION/$OF
echo "[$(date +%Y-%m-%d,%H:%M)] rsync done! Tar is next..."

#Compress the backup
cd $BLOCATION
tar -zcf $OF.tgz $OF
echo "[$(date +%Y-%m-%d,%H:%M)] Compressed and ready"

#Remove the non-compressed folder
rm -rf $BLOCATION/$OF
echo "[$(date +%Y-%m-%d,%H:%M)] Raw data removed"

#Remove backups older than MAXAGE
find $BLOCATION -mtime +$MAXAGE -type f -delete
echo "[$(date +%Y-%m-%d,%H:%M)] Old backups removed"

#Chmod-things
chown $BUSER $BLOCATION/$OF.tgz
echo "[$(date +%Y-%m-%d,%H:%M)] Ownership of $BLOCATION/$OF established"

echo "[$(date +%Y-%m-%d,%H:%M)] ====Done===="

exit
