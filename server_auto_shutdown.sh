#!/bin/bash

# This is machine autoshutdown script.
# It's intended to shutdown your cloud machine automatically to save your money.
# It's check for any user logged in or some processes are alive. If none of that is true for $n times in a row it shuts down the machine.

base=${base:-$HOME/.autooff}
log=${base}.log

store=${store:-${base}.store}
procs=${procs:-"python vim"}
n=${n:-3}
minutes=${minutes:-"*/5"}
crontime=${crontime:-"$minutes * * * *"}
croncmd="crontab -u root"


function isroot {
	[ $(id -u) -ne 0 ] && { echo Must be root; exit; }
}

function stop {
	echo -n > $store
}

function turnoff {
	stop
	shutdown -h now
}

function check {
	echo
	echo -n "========   "; date

	echo StopList processes: $procs

	if [ $(w -h | wc -l) -eq 0 ]; then
		echo No logged users found

		for p in $procs; do
			pgrep -x $p >/dev/null &&
				{ echo Process $p found;
					stop
					return; }
		done

		echo No processes found

		{ date; echo $(cat "$store" | wc -l) out of $n steps have done; } >> $store

		echo $(cat "$store" | wc -l) out of $n steps done before shutdown

		if [ $(cat "$store" | wc -l) -ge $n ]; then
			echo Going to shutdown...
			turnoff
		fi
	else
		echo User found
		w -h
		stop
	fi
}

case $1 in
	"check")
		isroot
		check
		;;
	"cronlist")
		isroot
		$croncmd -l
		;;
	"status")
		isroot
		echo $(cat "$store" 2>/dev/null | wc -l) out of $n steps have done before shutdown
		$croncmd -l | grep $(basename $0) && echo cron task is active || echo cron task is not active
		;;
	"logs")
		tail "$log"
		;;
	"cronadd")
		isroot
		full=`pwd`/$(basename $0)
		{ $croncmd -l 2>/dev/null | grep -v $0; echo "$crontime base=\"$base\" store=\"$store\" procs=\"$procs\" n=$n $full check >>$log" ; } | $croncmd -
		;;
	"cronrm")
		isroot
		if [ $($croncmd -l 2>/dev/null | grep -v $0 | wc -l) -eq 0 ]; then
			$croncmd -r
		else
			$croncmd -l 2>/dev/null | grep -v $0 | $croncmd -
		fi
		;;
	"showrights")
		echo User id: $(id -u)
		echo Homedir: $HOME
		echo procs: $procs
		;;
	help|--help|-h|*)
		echo Server auto shutdown script
		echo "  Available commands:"
		echo "    check     - check if somebody logged in or some processes are alive. Shutdown if none"
		echo "    status    - show current status"
		echo "    logs      - tails logs"
		echo "    cronlist  - list current cron tasks"
		echo "    cronadd   - add cron task to shutdown"
		echo "    cronrm    - remove current script from crontab"
		echo "    help      - print this help message"
		echo "  See available variables to configure in the beginning of the script"
		echo "  Example command"
		echo "    procs=\"python vim\" minutes=\"*/5\" n=3 $0 cronadd"
		;;
esac
