#!/bin/bash
# This script is based on https://github.com/puckel/docker-airflow/blob/master/script/entrypoint.sh

# Run sshd
#sleep infinity
su - root <<!
root
ssh-keygen -A
mkdir -p /run/sshd
/usr/sbin/sshd
!

mkdir -p "${AIRFLOW_HOME}/logs"
# wait enough for db
# To give the webserver time to run initdb.
sleep 20

case "$1" in
  master)
    airflow initdb

    nohup airflow webserver > "${AIRFLOW_HOME}/logs/webserver.log" 2>&1 &

    exec scheduler_failover_controller start
    ;;
  worker)
    nohup airflow worker > "${AIRFLOW_HOME}/logs/worker.log" 2>&1 &

    exec scheduler_failover_controller start
    ;;
  *)
    # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
    exec "$@"
    ;;
esac
