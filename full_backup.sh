#!/bin/bash
#The user doing the backup, needs access to all the files!
BUSER = backup-bot
#Location of the local backup
BLOCATION = /home/$BUSER/Backups
#Name of the backup
OF=$BLOCATION/$(date +%Y%m%d%h%m)-d-server
#Number of backups to keep (= how old should the oldest be if run once each day)
MAXAGE=7

echo "Starting full system backup..."

#The motherload....
rsync -aAXvHS --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found",$BLOCATION} / $OF

#Compress the backup
tar -xZf $OF.tgz $OF

#Remove backups older than a week

#for i in $( ls ); do
	#Get date from filename/file created
	#file_date = .....
	#age = $[$file_date - $(date +Y%m%d%h%m)] #file date - current date
	#if [$age >= $MAXAGE]; then
		rm -r i;
	#fi
#done
#Chmod-things

