#!/bin/bash

cmdname=$(basename $0)

echoerr()
{
if [ "$QUIET" -ne "1" ]
then
	>&2	echo "$@"
fi
}

usage()
{
	cat <<USAGE>&2

Test if a given TCP host/port are available using /usr/bin/timeout
Usage:
	$cmdname host:port [-s] [-t timeout] [-- command args]
	-h HOST | --host=HOST	Host or IP under test
	-p PORT | --port=PORT	TCP port under test
	Alternatively, you specify the host and port as host:port
	-s | --strict Only execute subcommand if the test succeeds
	-q | --quiet	Don't output any status messages
	-t TIMEOUT | --timeout=TIMEOUT Timeout in seconds, zero for no timeout
	-- COMMAND ARGS Execute command with args after the test finishes
USAGE
	exit 1
	# based on: https://github.com/double16/wait-for-it/blob/master/wait-for-it.sh
}


wait_for()
{
	if [ $TIMEOUT -gt 0 ]
	then
		echoerr $cmdname: waiting $TIMEOUT seconds for $HOST:$PORT
	else
		echoerr $cmdname: waiting for $HOST:$PORT forever
	fi
	start_ts=$(date +%s)
	while :
	do
		nc -z $HOST $PORT >/dev/null 2>&1
		RESULT=$?
		if [ $RESULT -eq 0 ]
		then
			end_ts=$(date +%s)
			echoerr $cmdname: $HOST:$PORT is available after $((end_ts - start_ts)) seconds
			break
		fi
		sleep 1
	done
	return $RESULT
}

wait_for_wrapper()
{
	# In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
	if [ $QUIET -eq 1 ]
	then
		/usr/bin/timeout $TIMEOUT $0 --quiet --child --host=$HOST --port=$PORT --timeout=$TIMEOUT &
	else
		/usr/bin/timeout $TIMEOUT $0 --child --host=$HOST --port=$PORT --timeout=$TIMEOUT &
	fi
	PID=$!
	trap "kill -INT -$PID" INT
	wait $PID
	RESULT=$?
	if [ $RESULT -ne 0 ]
	then
		echoerr $cmdname: timeout occurred after waiting $TIMEOUT seconds for $HOST:$PORT
	fi
	return $RESULT
}

# process arguments
while [ $# -gt 0 ]
do
	case "$1" in
		*:* )
			HOST=${1/:*/}
			PORT=${1/*:/}
			shift 1
		;;
		--child)
				CHILD=1
				shift 1
		;;
		-q | --quiet)
			QUIET=1
			shift 1
		;;
		-s | --strict)
			STRICT=1
			shift 1
		;;
		-h)
			HOST="$2"
			if [ "$HOST" == "" ]
			then
				break
			fi
			shift 2
		;;
		--host=*)
			HOST="${1#*=}"
			shift 1
		;;
		-p)
		PORT="$2"
			if [ "$PORT" == "" ]
			then
				break
			fi
			shift 2
		;;
		--port=*)
			PORT="${1#*=}"
			shift 1
		;;
		-t)
			TIMEOUT="$2"
			if [ "$TIMEOUT" == "" ]
			then
				break
			fi
			shift 2
		;;
			--timeout=*)
			TIMEOUT="${1#*=}"
			shift 1
		;;
		--)
			shift
			COMMAND="$@"
			break
		;;
		--help)
			usage
		;;
		*)
			echoerr Unknown argument: $1
			usage
		;;
	esac
done

if [[ "$HOST" == "" || "$PORT" == "" ]]
then
	echoerr Error: you need to provide a host and port to test.
	usage
fi

TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

if [ $CHILD -gt 0 ]
then
	wait_for
	RESULT=$?
	exit $RESULT
else
	if [ $TIMEOUT -gt 0 ]
	then
		wait_for_wrapper
		RESULT=$?
	else
		wait_for
		RESULT=$?
	fi
fi

if [ "$COMMAND" != "" ]
then
	if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]
	then
		echoerr $cmdname: strict mode, refusing to execute subprocess
		exit $RESULT
	fi
	exec $COMMAND
else
	exit $RESULT
fi