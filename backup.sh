#!/bin/bash
# Script fuer inkrementelles Backup mit 30 taegigem Vollbackup
set -x
### Einstellungen ##
BACKUPDIR="/mnt/backup"           ## Pfad zum Backupverzeichnis
ROTATEDIR="/mnt/backup/rotate"    ## Pfad wo die Backups nach 30 Tagen konserviert werden
TIMESTAMP="timestamp.dat"          ## Zeitstempel
SOURCE="/share/CACHEDEV1_DATA/Public/ /share/snapshot"               ## Verzeichnis(se) welche(s) gesichert werden soll(en)
DATUM="$(date +%d-%m-%Y)"          ## Datumsformat einstellen
ZEIT="$(date +%H:%M)"              ## Zeitformat einstellen >>Edit bei NTFS und Verwendung auch unter Windows : durch . ersetzen
MAILTO="lukas.flury@bluewin.ch"
MAILFROM="nas.alerts@bluewin.ch"
ANREDE="Hallo TBZ-Admin"
SIGNATUR="Freundlicher Gruss\nLukas Flury"
NFSSERVER="192.168.1.122"
REMOTEDIR="/volume1/backup"

### Verzeichnisse/Dateien welche nicht gesichert werden sollen ! Achtung keinen Zeilenumbruch ! ##
EXCLUDE="--exclude=/home/test1 --exclude=/home/test2"

### Wechsel in root damit die Pfade stimmen ##
cd /

### Backupverzeichnis anlegen ##
mkdir -p ${BACKUPDIR}

### Test ob Backupverzeichnis existiert und Mail an Admin bei fehlschlagen ##
if [ ! -d "${BACKUPDIR}" ]; then

        SUBJECT="Backupverzeichnis nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Verzeichnis ${BACKUPDIR} wurde nicht gefunden und konnte auch nicht angelegt werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

	. exit 1
fi

### NFS Volume mounten ###
mount -t nfs -o rw,auto,nfsvers=3,nolock $NFSSERVER:$REMOTEDIR $BACKUPDIR

if ! mount | grep "/mnt/backup" > /dev/null ; then
        echo "in the mount checker"
	SUBJECT="NFS-Mount nicht vorhanden!"
        TEXT="Das Backup am ${DATUM} konnte nicht erstellt werden. Das Verzeichnis ${BACKUPDIR} konnte nicht gemounted werden."
        echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t
        exit 1
fi


### Alle Variablen einlesen und letzte Backupdateinummer herausfinden ##
set -- ${BACKUPDIR}/backup-???.tgz
lastname=${!#}
backupnr=${lastname##*backup-}
backupnr=${backupnr%%.*}
backupnr=${backupnr//\?/0}
backupnr=$[10#${backupnr}]

### Backupdateinummer automatisch um +1 bis maximal 30 erhoehen ##
if [ "$[backupnr++]" -ge 30 ]; then
	mkdir -p ${ROTATEDIR}/${DATUM}-${ZEIT}

### Test ob Rotateverzeichnis existiert und Mail an Admin bei fehlschlagen ##
	if [ ! -d "${ROTATEDIR}/${DATUM}-${ZEIT}" ]; then

        	SUBJECT="Rotateverzeichnis nicht vorhanden!"
        	TEXT="Die alten Backups konnten am ${DATUM} nicht verschoben werden. Das Verzeichnis ${ROTATEDIR} wurde nicht gefunden und konnte auch nicht angelegt werden."
        	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

		. exit 1
	else
		### alter Code: mv ${BACKUPDIR}/* ${ROTATEDIR}/${DATUM}-${ZEIT}  Damit verschiebt er die Dateien in sich selbst weil rotate ein Unterverzeichnis von backup ist. Es kommt zur Fehlermeldung ##
		### /b* und /t* weil die Dateien nur mit b und t beginnen ##
		mv ${BACKUPDIR}/b* ${ROTATEDIR}/${DATUM}-${ZEIT}
		mv ${BACKUPDIR}/t* ${ROTATEDIR}/${DATUM}-${ZEIT}
	fi

	### Abfragen ob das Backupverschieben erfolgreich war ##
	if [ $? -ne 0 ]; then
        	SUBJECT="Backupverschieben fehlerhaft!"
        	TEXT="Die alten Backups konnte am ${DATUM} nicht verschoben werden."
        	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

		exit 1
	else
        	SUBJECT="Backupverschieben erfolgreich"
	        TEXT="Die alten Backups wurde am ${DATUM} erfolgreich nach ${ROTATEDIR}/${DATUM}-${ZEIT} verschoben."
        	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

		### die Backupnummer wieder auf 1 stellen ##
		backupnr=1
	fi
fi

backupnr=000${backupnr}
backupnr=${backupnr: -3}
filename=backup-${backupnr}.tgz

### Nun wird das eigentliche Backup ausgefuehrt ##
tar -cpzf ${BACKUPDIR}/${filename} -g ${BACKUPDIR}/${TIMESTAMP} ${SOURCE} ${EXCLUDE}

### Abfragen ob das Backup erfolgreich war ##
if [ $? -ne 0 ]; then
	SUBJECT="Backup (${SOURCE}) war fehlerhaft!"
	TEXT="Das Backup ${filename} am ${DATUM} konnte erstellt werden, jedoch mit Warnungen."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

else
	SUBJECT="Backup (${SOURCE}) war erfolgreich"
	TEXT="Das Backup ${filename} am ${DATUM} wurde erfolgreich beendet."
	echo -e "To: $MAILTO \nFrom: $MAILFROM \nSubject: $SUBJECT \n\n $ANREDE\n\n $TEXT \n\n $SIGNATUR" | sendmail -t

fi
