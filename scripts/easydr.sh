#!/bin/bash

#set -x

Usage() {
    echo "Usage: $0 {start|stop|restart|status}" 1>&2
    exit 1
}

check_VbServer_state () {
    ps -ef |grep /etc/easydr/site-packages/VbServer.py |grep -q -v grep
}

start_VbServer () {
    if ! check_VbServer_state; then
	bash -c "/usr/bin/python2.6 /etc/easydr/site-packages/VbServer.py >/dev/null &"
        sleep 2
        if check_VbServer_state; then
	    return 0
	else
	    return 1
        fi
    else
	return 0
    fi
}

stop_VbServer () {
    if check_VbServer_state; then
	kill -9 $(ps -ef |grep -v grep|grep /etc/easydr/site-packages/VbServer.py | awk '{ print $2 }')
        sleep 2
        if ! check_VbServer_state; then
	    return 0
	else
	    return 1
	fi
    fi
}

EasyDR_isrunning() {
    ps -ef | grep -v grep | grep -q /sbin/EasyDR.py
}

start() {
    if ! EasyDR_isrunning; then
	if start_VbServer; then
	    bash -c "/usr/bin/python2.6 /sbin/EasyDR.py >/dev/null &"
            if EasyDR_isrunning; then
	        echo "EasyDR start successfully."
	    else
		echo "EasyDR start failed."
            fi
	else
	    echo
	    echo "EasyDR start failed, Because VbServer start failed."
	    exit 1
        fi
    else
	echo "EasyDR is already started."
    fi
}

stop() {
    if EasyDR_isrunning; then
	kill -9 $(ps -ef |grep -v grep|grep EasyDR | awk '{ print $2 }')
        if ! EasyDR_isrunning; then
	    if stop_VbServer; then
	        echo "EasyDR stop successfully."
	    else
	        echo "EasyDR stop failed."
            fi
        fi
    else
	echo "EasyDR is already stopped."
    fi
}

[ $# -ne 1 ] && Usage

case "$1" in
	start)
 	    start
	    ;;
	stop)
	    stop
	    ;;
	restart)
	    stop
	    start
	    ;;
	status)
	    if EasyDR_isrunning; then
		EasyDR_PID=$(ps -ef |grep /sbin/EasyDR.py |grep -v grep | awk '{ print $2}')
                echo -n 'EasyDR '
		echo "(pid $EasyDR_PID) is running..."
            else
                echo 'EasyDR is stopped.'
            fi
            ;;
	v|ver|version)
	    echo "2.0"
	    ;;
	*)
	    Usage
	    ;;
esac
