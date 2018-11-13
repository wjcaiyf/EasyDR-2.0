#!/bin/bash

while :
do
    read -p "Are you sure to uninstall [ yes/no ]: " answer
    answer=`echo $answer | tr -s A-Z a-z`
    [ X"$answer" = X ] && continue
    [ X"$answer" != X"yes" -a X"$answer" != X"no" ] && continue
    [ X"$answer" = X"yes" ] && break
    [ X"$answer" = X"no" ] && exit 0
done

set -x
pidof recordmydesktop > /dev/null
if [ $? -eq 0 ]; then
    echo
    echo -e "\033[31m[ERROR] \033[0mFind video task, can not execute the uninstall operation."
    echo
    [ -f /sbin/video_report -a -x /sbin/video_report ] && /sbin/video_report 
    exit 1
fi

edr_pid=$(ps -ef |grep -v grep |grep /sbin/EasyDR.py | awk '{ print $2 }')
if [ -n "$edr_pid" ]; then
    kill -9 $edr_pid
fi
vbserver_pid=$(ps -ef |grep -v grep | grep /etc/easydr/site-packages/VbServer.py | awk '{ print $2 }')
if [ -n "$vbserver_pid" ]; then
    kill -9 $vbserver_pid
fi

yum -y remove gtk-recordmydesktop jack-audio-connection-kit jack-audio-connection-kit-example-clients recordmydesktop &>/dev/null

sed -i '/\/sbin\/easydr start/d' /etc/rc.d/rc.local
rm -rf /sbin/EasyDR.py
rm -rf /sbin/easydr
rm -rf /etc/easydr

set +x
