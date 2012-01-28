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

NAME=<%=autossh_name%>
PIDFILE=/var/run/${NAME}.pid
SCRIPTNAME=/etc/init.d/${NAME}
DAEMON=/usr/lib/autossh/autossh
SCRIPTNAME=/etc/init.d/${NAME}
DESC="Autossh Tunnel for ${NAME}"
MPORT=<%=autossh_monitoring_port%>
PORT=<%=autossh_port%>
REMOTEUSER=<%=autossh_remote_user%>
REMOTEHOST=<%=autossh_remote_host%>
REMOTETARGET=<%=autossh_remote_target_host%>
REMOTETARGET_PORT=<%=autossh_remote_target_port%>
REMOTE_PRIVATE_KEY_LOCATION=<%=autossh_remote_private_key_location%>

export AUTOSSH_PIDFILE=${PIDFILE}

test -x $DAEMON || exit 0

DAEMON_ARGS="-M ${MPORT} -f -N -L ${PORT}:${REMOTETARGET}:${REMOTETARGET_PORT} ${REMOTEUSER}@${REMOTEHOST} -- -i ${REMOTE_PRIVATE_KEY_LOCATION}"

#
# Function that starts the daemon/service
#
do_start()
{
        # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        start-stop-daemon --start --quiet --pidfile $PIDFILE  --exec $DAEMON --test > /dev/null \
                || return 1
        start-stop-daemon --start --quiet --pidfile $PIDFILE  --exec $DAEMON -- \
                $DAEMON_ARGS \
                || return 2
        # Add code here, if necessary, that waits for the process to be ready
        # to handle requests from services started subsequently which depend
        # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --exec $DAEMON
        RETVAL="$?"
        [ "$RETVAL" = 2 ] && return 2
        # Wait for children to finish too if this is a daemon that forks
        # and if the daemon is only ever run from this initscript.
        # If the above conditions are not satisfied then add some other code
        # that waits for the process to drop all resources that could be
        # needed by services started subsequently.  A last resort is to
        # sleep for some time.
        start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
        [ "$?" = 2 ] && return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f $PIDFILE
        return "$RETVAL"
}



case "$1" in
  start)
	echo -n "Starting $DESC: $NAME"
	do_start
	echo "."
	;;
  stop)
	echo -n "Stopping $DESC: $NAME"
	do_stop
	echo "."
	;;

  restart)
	echo -n "Restarting $DESC: $NAME"
	do_stop
	sleep 1
	do_start
	echo "."
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart}" >&2
	exit 3
	;;
esac

exit 0
