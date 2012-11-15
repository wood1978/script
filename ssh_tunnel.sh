#!/bin/bash
#
# A simple script to set up or stop a SSH tunnel
# to my home server.
#
# Usage:
#
# ssh_tunnel.sh LOCAL_PORT REMOTE_URL start
# Sets up the tunnel and saves the PID in /tmp/ssh_tunnel_id.txt
#
# ssh_tunnel.sh stop
# Reads the process id from /tmp/ssh_tunnel_id.txt and kills that process.

PIDFILE=/tmp/ssh_tunnel_pid.txt

if [ $# -eq 1 ] && [ $1 = stop ] ; then
	if [ -f $PIDFILE ] ; then
		kill `cat $PIDFILE`
		rm $PIDFILE
		echo "Tunnel has been closed."
	else
		echo "Cannot find a PID file $PIDFILE.  Are you sure a tunnel \
			is open?"
	fi
elif [ $# -eq 3 ] && [ $3 = start ] ; then
	PORT=$1
	REMOTE=$2

	if [ -f $PIDFILE ] ; then
		echo "A tunnel is already opened.  No action has been taken."
	else
		autossh -M 1234 -ND 127.0.0.1:$PORT $REMOTE &
		echo $! > $PIDFILE
		echo "Tunnel has been opened on localhost:$PORT"
	fi
else
	echo "Use \"$0 LOCAL_PORT REMOTE_URL start\" to start a proxy, \
		or \"$0 LOCAL_PORT REMOTE_URL stop\" to stop the proxy."
fi

