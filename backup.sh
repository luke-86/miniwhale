#!/bin/bash

### Einstellungen ##
BACKUPDIR="/mnt/backup"           ## Pfad zum Backupverzeichnis
ARCHIVEDIR="/mnt/backup/archive"    ## Pfad wo die Backups nach 30 Tagen konserviert werden
FILENAME="backup-$(date +'%F_%H-%M').tar"
REMOTEDIR="/volume1/backup"
BACKUPLOG="/var/log/backup.log"
SOURCE="/share/CACHEDEV1_DATA/Public/ /share/snapshot"               ## Verzeichnis(se) welche(s) gesichert werden soll(en)
DATUM="$(date +'%F %T')"          ## Datumsformat einstellen
MAILTO="lukas.flury@bluewin.ch"
MAILFROM="nas.alerts@bluewin.ch"
ANREDE="Hallo TBZ-System-Administrator"
SIGNATUR="Freundlicher Gruss\nIhr Systemadministator"
NFSSERVER="192.168.1.122"

### Verzeichnisse/Dateien welche nicht gesichert werden sollen ! Achtung keinen Zeilenumbruch ! ##
EXCLUDE="--exclude=*.sock --exclude=*.socket --exclude=*.iso --exclude=*.img --exclude=*.qvm --exclude=/share/CACHEDEV1_DATA/Public/virtualization-station-data --exclude=/share/CACHEDEV1_DATA/Public/VM-Images --exclude=/share/CACHEDEV1_DATA/Public/container-station-data/lib/docker/devicemapper/devicemapper/data --exclude=*/devicemapper/data"

### Backupverzeichnis anlegen ##
mkdir -p ${BACKUPDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ##
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


### Alle Variablen einlesen und letzte Backupdateinummer herausfinden ##
mkdir -p ${ARCHIVEDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ##
if [ ! -d "${ARCHIVEDIR}" ]; then

        SUBJECT="Archivierungs-Verzeichnis nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Archiv-Verzeichnis ${ARCHIVEDIR} wurde nicht gefunden und konnte auch nicht angelegt werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	exit 1
fi

### Backup-Archivierung für Datein die Aelter sind als14 Tage ##
find $BACKUPDIR -maxdepth 1 -mtime +1 -type f -exec mv "{}" $ARCHIVEDIR \;

### Archivierungs-Cleanup für Datein die Aelter sind als14 Tage ##
find $ARCHIVEDIR -maxdepth 1 -mtime +3 -type f -delete

### Ausfuehren des eigentlichen Backups ##
echo "###### Starting Backup ${FILENAME} ######" >> $BACKUPLOG
tar -cpvf ${BACKUPDIR}/${FILENAME} ${EXCLUDE} ${SOURCE} >>$BACKUPLOG 2>&1
echo "###### Backup ${FILENAME} finished ######" >> $BACKUPLOG

### Abfragen ob das Backup erfolgreich war ##
if [ $? -eq 0 ]; then
	SUBJECT="Backup (${SOURCE}) war erfolgreich"
	TEXT="Das Backup ${FILENAME} am ${DATUM} wurde erfolgreich beendet."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	
elif [ $? -eq 1 ]; then
	SUBJECT="Backup (${SOURCE}) war erfolgreich, jedoch mit Warnungen!"
	TEXT="Das Backup ${FILENAME} am ${DATUM} wurde erfolgreich beendet, jedoch entstanden waehrend dem Backup Warnungen. Siehe Log (${BACKUPLOG}) für Details."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
	
else
	SUBJECT="Backup (${SOURCE}) war fehlerhaft!"
	TEXT="Das Backup ${FILENAME} am ${DATUM} konnte nicht erstellt werden! Siehe Log (${BACKUPLOG}) für Details."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

fi
