#!/bin/bash
#The user doing the backup, needs access to all the files!
BUSER="backup-bot"
#Location of the local backup
BLOCATION="/backup"
#Name of the backup
OF=$(date +%Y%m%d%H%M)_d-server
#Number of backups to keep (= how old should the oldest be if run once each day)
MAXAGE=7
#Log file location
LOG="var/log/backup.log"

#Output STDOUT & STDERR both to log-file and terminal
exec > >(tee -ia /var/log/backup.log)
exec 2> >(tee -ia /var/log/backup.log)

echo "Starting full system backup at $(date ,%H:%M)"
echo "Mounting /dev/vda1 to $BACKUP..."

if grep -qs "$BLOCATION" /proc/mounts; then
  echo "It's already mounted."
else
  mount "$mount"
  if [ $? -eq 0 ]; then
   echo "Mounted!"
  else
   echo "Something went wrong with the mount, exiting"
   exit
  fi
fi

mkdir $BLOCATION/$OF

if [ ! -d "$BLOCATION/$OF" ]; then
	echo "Problem creating the backup folder $BLOCATION/$OF, exiting..."
	exit
fi
echo "Backuplocation $BLOCATION/$OF created"
#The motherload....
echo "Starting rsync..."
rsync -aAXvHS --exclude={"/var/cache/*","/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","$BLOCATION/*"} / $BLOCATION/$OF

echo "rsync done! Tar is next..."

#Compress the backup
cd $BLOCATION
tar -zcf $OF.tgz $OF
echo "Compressed and ready"

#Remove the non-compressed folder
rm -rf $BLOCATION/$OF
echo "Raw data removed"

#Remove backups older than MAXAGE
#find $BLOCATION -mtime +$MAXAGE -type f -delete
echo "Old backups removed"

#Chmod-things
chown backup-bot:admins $BLOCATION/$OF.tgz
echo "Ownership established"

#Unmount
umount $BLOCATION
echo "Unmounted $BLOCATION"
echo "$(date +%H:%M)Done"

exit
