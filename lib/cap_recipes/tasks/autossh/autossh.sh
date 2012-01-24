#! /bin/sh
#
### BEGIN INIT INFO
# Provides:          autossh
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $named
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Autossh Tunnel Init
# Description:       Autossh Tunnel init scripts
### END INIT INFO
#
# Rick Russell sysadmin.rick@gmail.com
#

depend() {
      use logger dns
      need net
}

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

NAME=`basename $0`
PIDFILE=/var/run/${NAME}.pid
SCRIPTNAME=/etc/init.d/${NAME}
DAEMON=/usr/bin/autossh
SCRIPTNAME=/etc/init.d/${NAME}
DESC="Autossh Tunnel"
MPORT=5122
TUNNEL="-L 3305:"##MASTER##":3306"
REMOTEUSER=<%=mysql_repl_user%>
REMOTESERVER=##AUTOSSH_REMOTE##
KEYFILE="/home/repl/.ssh/id_rsa.pub"

export AUTOSSH_PIDFILE=${PIDFILE}

test -x $DAEMON || exit 0

ASOPT="-M "${MPORT}" -f -N "${TUNNEL}" "${REMOTEUSER}"@"${REMOTESERVER}


#	Function that starts the daemon/service.
d_start() {
	start-stop-daemon --start --quiet --pidfile $PIDFILE \
		--exec $DAEMON -- $ASOPT
	if [ $? -gt 0 ]; then
	    echo -n " not started (or already running)"
	else
	    sleep 1
	    start-stop-daemon --stop --quiet --pidfile $PIDFILE \
		--test --exec $DAEMON > /dev/null || echo -n " not started"
	fi

}

#	Function that stops the daemon/service.
d_stop() {
	start-stop-daemon --stop --quiet --pidfile $PIDFILE \
		--exec $DAEMON \
		|| echo -n " not running"
}


case "$1" in
  start)
	echo -n "Starting $DESC: $NAME"
	d_start
	echo "."
	;;
  stop)
	echo -n "Stopping $DESC: $NAME"
	d_stop
	echo "."
	;;

  restart)
	echo -n "Restarting $DESC: $NAME"
	d_stop
	sleep 1
	d_start
	echo "."
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart}" >&2
	exit 3
	;;
esac

exit 0
