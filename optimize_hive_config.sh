#!/bin/bash

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)

#
# Check return codes
#
check_rc () {
  if [ $1 -ne 0 ]; then
    echo "ERROR"
    exit 1
  else
    echo "SUCCESS"
  fi
}

# Get the Ambari admin password from the user
echo -e "\n### Enter the Ambari admin user password: \c"; read LAB_PW

# Increase the amount of memory available to YARN
echo -e "\n### Increasing the amount of memory allocated to YARN"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox yarn-site "yarn.nodemanager.resource.memory-mb" "8192"
check_rc $?

# Increase the minimum yarn allocation
echo -e "\n### Increasing the minimum memory allocation for yarn"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox yarn-site "yarn.scheduler.minimum-allocation-mb" "2048"
check_rc $?

# Increase the maximum yarn allocation
echo -e "\n### Increasing the maximum memory allocation for yarn"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox yarn-site "yarn.scheduler.maximum-allocation-mb" "8192"
check_rc $?

# Set hive.tez.container.size to avoid OOM
echo -e "\n### Increasing the tez container size"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox hive-site "hive.tez.container.size" "2048"
check_rc $?

# Set hive.tez.java.opts to increase the heap
echo -e "\n### Increasing the tez container heap size"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox hive-site "hive.tez.java.opts" "-server -Xmx1532m -Djava.net.preferIPv4Stack=true"
check_rc $?

# Increase the tez application master container size
echo -e "\n### Increasing the tez application master container size"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox tez-site "tez.am.resource.memory.mb" "2048"
check_rc $?

# Increase the tez application master container size
echo -e "\n### Increasing the tez task container size"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox tez-site "tez.task.resource.memory.mb" "2048"
check_rc $?

# Increase the tez jvm heap
echo -e "\n### Increasing the tez jvm heap"
/var/lib/ambari-server/resources/scripts/configs.sh -u admin -p $LAB_PW set localhost Sandbox tez-site "tez.task.launch.cmd-opts" "-Xmx1532m"
check_rc $?

# Start Hive mysql
echo -e "\n### Starting up Hive's mysql instance"
export SERVICE=HIVE
export AMBARI_HOST=localhost
export CLUSTER=Sandbox
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Hive via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 60
check_rc $?

# Restart hive
echo -e "\n### Restarting Hive for configuration changes"
export SERVICE=HIVE
export AMBARI_HOST=localhost
export CLUSTER=Sandbox
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop Hive via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 60
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Hive via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 240
check_rc $?

# Restart Oozie
echo -e "\n### Restarting Oozie for configuration changes"
export SERVICE=OOZIE
export AMBARI_HOST=localhost
export CLUSTER=Sandbox
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop Oozie via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 60
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Oozie via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 120
check_rc $?

# Restart yarn
echo -e "\n### Restarting YARN for configuration changes"
export SERVICE=YARN
export AMBARI_HOST=localhost
export CLUSTER=Sandbox
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop YARN via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 60
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start YARN via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 120
check_rc $?

# Restart Tez
echo -e "\n### Restarting Tez for configuration changes"
export SERVICE=TEZ
export AMBARI_HOST=localhost
export CLUSTER=Sandbox
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop Tez via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 60
curl -u admin:$LAB_PW -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Tez via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}'  http://$AMBARI_HOST:8080/api/v1/clusters/$CLUSTER/services/$SERVICE && sleep 120
check_rc $?

exit 0
