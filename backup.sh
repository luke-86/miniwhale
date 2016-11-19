#!/bin/bash

### Einstellungen ##
MAILTO="lukas.flury@bluewin.ch"
MAILFROM="nas.alerts@bluewin.ch"
ANREDE="Hallo TBZ-System-Administrator"
SIGNATUR="Freundlicher Gruss\nLukas Flury"
NFSSERVER="172.16.16.104"

### Variablen ##
BACKUPDIR="/mnt/backup"
ARCHIVEDIR="/mnt/backup/archive"
FILENAME="backup-$(date +'%F_%H-%M').tar"
REMOTEDIR="/volume1/backup"
BACKUPLOG="/share/CACHEDEV1_DATA/backup/backup.log"
SOURCE="/share/CACHEDEV1_DATA/Public/ /share/snapshot /etc"
DATUM="$(date +'%F %T')"

### Verzeichnisse/Dateien welche nicht gesichert werden (excludes) ###
EXCLUDE="--exclude=*.sock --exclude=*.socket --exclude=*.iso --exclude=*.img --exclude=*.qvm --exclude=/share/CACHEDEV1_DATA/Public/virtualization-station-data --exclude=/share/CACHEDEV1_DATA/Public/VM-Images --exclude=/share/CACHEDEV1_DATA/Public/container-station-data/lib/docker/devicemapper/devicemapper/data --exclude=*/devicemapper/data"

### Backupverzeichnis anlegen ###
mkdir -p ${BACKUPDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ###
if [ ! -d "${BACKUPDIR}" ]; then

        SUBJECT="Backupverzeichnis nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Verzeichnis ${BACKUPDIR} wurde nicht gefunden und konnte auch nicht angelegt werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	exit 1
fi

### NFS Volume mounten ###
if ! mount | grep "/mnt/backup" > /dev/null ; then
	mount -t nfs -o rw,auto,nfsvers=3,nolock $NFSSERVER:$REMOTEDIR $BACKUPDIR
	sleep 10
fi

if ! mount | grep "/mnt/backup" > /dev/null ; then
	SUBJECT="NFS-Mount nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Backup-Verzeichnis ${BACKUPDIR} konnte nicht gemounted werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
        exit 1
fi


### Erstellen des Archiv-Verzeichnis ###
mkdir -p ${ARCHIVEDIR}

### Test ob Archiv-Verzeichnis existiert und Mail an Admin bei fehlschlagen ###
if [ ! -d "${ARCHIVEDIR}" ]; then

        SUBJECT="Archivierungs-Verzeichnis nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Archiv-Verzeichnis ${ARCHIVEDIR} wurde nicht gefunden und konnte auch nicht angelegt werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	exit 1
fi

### Backup-Archivierung für Datein die Aelter sind al 14 Tage ###
find $BACKUPDIR -maxdepth 1 -mtime +14 -type f -exec mv "{}" $ARCHIVEDIR \;

### Archivierungs-Cleanup für Datein die Aelter sind al 30 Tage ###
find $ARCHIVEDIR -maxdepth 1 -mtime +30 -type f -delete

### Ausfuehren des eigentlichen Backups ###
echo "###### Starting Backup ${FILENAME} ######" >> $BACKUPLOG
tar -cpf ${BACKUPDIR}/${FILENAME} ${EXCLUDE} ${SOURCE} >>$BACKUPLOG 2>&1
echo "###### Backup ${FILENAME} finished ######" >> $BACKUPLOG

### Abfragen ob das Backup erfolgreich war ##
if [ $? -eq 0 ]; then
	SUBJECT="Backup (${FILENAME}) war erfolgreich"
	TEXT="Das Backup ${FILENAME} am ${DATUM} wurde erfolgreich beendet."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	
elif [ $? -eq 1 ]; then
	SUBJECT="Backup (${FILENAME}) war erfolgreich, jedoch mit Warnungen!"
	TEXT="Das Backup ${FILENAME} am ${DATUM} wurde erfolgreich beendet, jedoch entstanden waehrend dem Backup Warnungen. Siehe Log (${BACKUPLOG}) für Details."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	
else
	SUBJECT="Backup (${FILENAME}) war fehlerhaft!"
	TEXT="Das Backup ${FILENAME} am ${DATUM} konnte nicht erstellt werden! Siehe Log (${BACKUPLOG}) für Details."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

fi
