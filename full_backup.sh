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

#Mount, here add options here
MOUNT="/dev/vda1"

ADMINEMAIL="webbutskottet@d.lintek.liu.se"

#Send email if quitting in an unusial way
function term {
  echo "[$(date +%Y-%m-%d,%H:%M)] Termination, sending email to $ADMINEMAIL"
  #echo "The actual message goes here" | mailx -v -r "user@domain.com" -s "The actual subject line goes here" -S smtp="smtp.domain.com:587" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="user@domain.com" -S smtp-auth-password="password123" -S ssl-verify=ignore the_recipient_email@domain.com

  echo -e "Backup of d-sektionen failed :(\nLast 20 log entries were:\n$( tail -n 20 /var/log/backup.log )" | mailx -v -r $ADMINEMAIL -s 'Backup of d-sektionen.se failed $(date +%Y-%m-%d,%H:%M)' -S smtp="aspmx.l.google.com" $ADMINEMAIL

  echo "[$(date +%Y-%m-%d,%H:%M)] Exiting..."
  exit
}

#Output STDOUT & STDERR both to log-file and terminal
exec > >(tee -ia /var/log/backup.log)
exec 2> >(tee -ia /var/log/backup.log)

echo "[$(date +%Y-%m-%d,%H:%M)] ####Starting full system backup####"
echo "[$(date +%Y-%m-%d,%H:%M)] Mounting $MOUNT to $BACKUP..."

if grep -qs "$BLOCATION" /proc/mounts; then
  echo "[$(date +%Y-%m-%d,%H:%M)] It's already mounted."
else
  mount "$MOUNT"
  if [ $? -eq 0 ]; then
   echo "[$(date +%Y-%m-%d,%H:%M)] Mounted!"
  else
   echo "[$(date +%Y-%m-%d,%H:%M)] Something went wrong with the mount, exiting"
   term
  fi
fi

mkdir $BLOCATION/$OF

if [ ! -d "$BLOCATION/$OF" ]; then
	echo "[$(date +%Y-%m-%d,%H:%M)] Problem creating the backup folder $BLOCATION/$OF, exiting..."
	term
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
