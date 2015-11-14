#!/bin/bash

CONFIGDIR="/home/ajdukm/Tunnels/etc"
CONFIGFILE=$CONFIGDIR/"config.sh"
source "$CONFIGFILE";

/usr/sbin/logrotate --state $LOGDIR/logrotate.status $CONFIGDIR/"logrotate.cfg"  >> $LOGDIR/$LOGFILE 2>&1
#Solaris
#/usr/sbin/logadm -f $CONFIGDIR/logadm.cfg >> $LOGDIR/$LOGFILE 2>&1

echo `date $LOGDATEFORMAT`" +++++++++++++++++++++++ RUN START +++++++++++++++++++++++" >> $LOGDIR/$LOGFILE 2>&1

$INSTALLDIR/bin/check.sh $CONFIGFILE host 2775 >> $LOGDIR/$LOGFILE 2>&1
ret=$?
if [ "$ret" -lt "1" ]; then
  #Parametry TARGET_HOST TARGET_PORT KONIEC_TUNELU USER@KONIEC_TUNELU SKRYPT_LOGOWANIA
  $INSTALLDIR/bin/connect.sh $CONFIGFILE host 2775 localhost user $INSTALLDIR/bin/ssh_pass.pl >> $LOGDIR/$LOGFILE 2>&1
fi

$INSTALLDIR/bin/check.sh $CONFIGFILE host 8081 >> $LOGDIR/$LOGFILE 2>&1
ret=$?
if [ "$ret" -lt "1" ]; then
  $INSTALLDIR/bin/connect.sh $CONFIGFILE host 8081 localhost user $INSTALLDIR/bin/ssh_pass.pl >> $LOGDIR/$LOGFILE 2>&1
fi

echo `date $LOGDATEFORMAT`" +++++++++++++++++++++++ RUN   END +++++++++++++++++++++++"  >> $LOGDIR/$LOGFILE 2>&1
