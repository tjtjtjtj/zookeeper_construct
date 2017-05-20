#!/bin/bash

echo "zookeeper install started"

host="
192.168.33.20
192.168.33.21
192.168.33.22
"
i=0
for h in ${host}
do
  echo ${h}
  i=$(( i + 1 ))
  echo ${i}
  ssh jenkins@${h} "sudo yum -y install java"
  ssh jenkins@${h} "sudo rm -rf /opt/zookeeper-3.4.10"
  scp /tmp/zookeeper-3.4.10.tar.gz ${h}:/tmp/
  ssh jenkins@${h} "sudo tar xzf /tmp/zookeeper-3.4.10.tar.gz -C /opt"
  scp /tmp/zoo.cfg ${h}:/opt/zookeeper-3.4.10/conf
  ssh jenkins@${h} "sudo chown -R root:root  /opt/zookeeper-3.4.10"
  ssh jenkins@${h} "sudo bash -c 'echo ${i} > /opt/zookeeper-3.4.10/myid'"
  ssh jenkins@${h} "sudo /opt/zookeeper-3.4.10/bin/zkServer.sh start"
  ssh jenkins@${h} "sudo yum -y install nc"
  sleep 10
  echo ruok |nc ${h} 2181 
done

echo "zookeeper installed"
