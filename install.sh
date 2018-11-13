#!/bin/bash

set -e

Usage() {
    cat <<EOF
Usage: $0 { -i -d video_directory | -u }

       -i Install.
       -u Update.
       -d Specify a directory to store videos.
EOF
    exit 1
}

install_easydr() {
    rpm -q recordmydesktop &>/dev/null && echo "[INFO] EasyDR has already been installed." && exit 0
    #===========================================
    # variables
    #===========================================
    storage_path=${1%/}

    echo -e "\033[1;4m1:\033[0m  install recordmydesktop ..."
    yum -y install packages/*.rpm >/dev/null
    #if [ $? -ne 0 ]; then
    #   echo -e "\033[31minstall recordmydesktop failed\033[0m"
    #   exit 1
    #fi

    [ ! -d /etc/easydr ] && mkdir -p /etc/easydr
    [ ! -d /etc/easydr/tools ] && mkdir -p /etc/easydr/tools
    #===========================================
    # add and set scripts
    #===========================================

    echo -e "\033[1;4m2:\033[0m  some set tasks ..."

    scp -r site-packages /etc/easydr/
    scp scripts/EasyDR.py /sbin
    scp scripts/easydr.sh /sbin/easydr
    scp scripts/uninstall.sh /etc/easydr/tools/EasyDR_uninstall
    scp easydr.conf /etc/easydr/
    chmod 0755 /sbin/easydr
    chmod 0755 /etc/easydr/tools/EasyDR_uninstall
    sed -i "s,%STORAGE_PATH%,${storage_path}," /etc/easydr/site-packages/handler_dr.py

    #============================================
    #   set EasyDR to start on system boot
    #============================================
    if ! grep -q "EasyDR\.py" /etc/rc.d/rc.local; then
        #cp /etc/rc.d/rc.local /etc/rc.d/rc.local-before-modify-`date +%Y-%m-%d-%H-%M-%S`
        sed -i '/touch \/var\/lock\/subsys\/local/d' /etc/rc.d/rc.local
	cat >> /etc/rc.d/rc.local <<-EOF
	/sbin/easydr start
	touch /var/lock/subsys/local
	EOF
    fi

    #if ! ps -ef | grep -v grep | grep -q EasyDR.py ; then
    #    bash -c "/usr/bin/python /sbin/EasyDR.py >/dev/null &"
    #fi

    echo
    echo "You can find videos in \"${storage_path}/easydr/videos\" directory."
    echo "You can find EasyDR log in \"${storage_path}/easydr/logs\" directory."
    echo
}

update_easydr() {
    rpm -q recordmydesktop >/dev/null || NOT_INSTll=yes
    [ ! -f /sbin/EasyDR.py ] && NOT_INSTALL=yes
    [ ! -f /sbin/easydr ] && NOT_INSTALL=yes
    [ "${NOT_INSTALL}" = "yes" ] && {
	echo "[WARN]: No installed EasyDR found, cat not do update action."
	exit 1
	}
    echo "updating ..."
    if grep -q log_video_basedir /sbin/EasyDR.py; then
        origin_ref_file=/sbin/EasyDR.py
    else
        origin_ref_file=/etc/easydr/site-packages/handler_dr.py
    fi
    origin_sp=$(grep "^log_video_basedir" $origin_ref_file | sed -n '1p' | awk -v FS="'" '{ print $2}')

    edr_pid=$(ps -ef |grep -v grep |grep /sbin/EasyDR.py | awk '{ print $2 }')
    if [ -n "$edr_pid" ]; then
        kill -9 $edr_pid
    fi

    scp -r site-packages /etc/easydr/
    scp scripts/EasyDR.py /sbin
    scp scripts/easydr.sh /sbin/easydr
    [ ! -d /etc/easydr/tools ] && mkdir -p /etc/easydr/tools
    scp scripts/uninstall.sh /etc/easydr/tools/EasyDR_uninstall
    scp easydr.conf /etc/easydr/

    chmod 0755 /sbin/easydr
    chmod 0755 /etc/easydr/tools/EasyDR_uninstall

    sed -i "s,%STORAGE_PATH%,${origin_sp}," /etc/easydr/site-packages/handler_dr.py

    sed -i '/\/sbin\/EasyDR\.py/d' /etc/rc.d/rc.local
    sed -i '/touch \/var\/lock\/subsys\/local/d' /etc/rc.d/rc.local
    if ! grep -q '/sbin/easydr start' /etc/rc.d/rc.local; then
        sed -i '$a\/sbin/easydr start' /etc/rc.d/rc.local
    fi
    if ! grep -q 'touch /var/lock/subsys/local' /etc/rc.d/rc.local; then
        sed -i '$a\touch /var/lock/subsys/local' /etc/rc.d/rc.local
    fi

    echo
    echo "Don't forget to use \"easydr start\" to start easydr after modified easydr configuration file."
    echo 
    echo "update finished."
    echo 
}

[ $# -eq 0 ] && Usage

while getopts "id:uh" OPT
do
    case "$OPT" in
	i)
	    INSTALL=yes
	    ;;
	d)
	    VIDEO_DIRECTORY=$OPTARG
	    ;;
	u)
	    UPDATE=yes
	    ;;
	?|h)
    	    Usage
	    ;;
    esac
done

echo $VIDEO_DIRECTORY | grep -q "^\-" && echo "$0: option requires an argument -- d" && exit 1
[ -z "$INSTALL" -a -z "$UPDATE" ] && echo "[WARN]: You must specify  \"-i\" or \"-u\" option." && exit 1
[ -n "$INSTALL" -a -n "$UPDATE" ] && echo "[WARN]: Options \"-i\" and \"-u\" cannot be specified at the same time." && exit 1

if [ "$INSTALL" = "yes" ]; then
    if [ -z "$VIDEO_DIRECTORY" ]; then
	echo "[WARN]: You select install action, so must specify \"-d\" option."
	exit 1
    fi
    echo $VIDEO_DIRECTORY | grep -q "^\-" && echo "$0: option requires an argument -- d" && exit 1
    install_easydr $VIDEO_DIRECTORY
elif [ "$UPDATE" = "yes" ]; then
    update_easydr
fi
