#!/bin/bash

# 获取 kube-proxy 进程的 ID
KUBE_PROXY_PID=$(pgrep -f kube-proxy)
MQTT_PROXY_PID=$(pgrep -f mq)

if [ -z "$KUBE_PROXY_PID" ]; then
  kill -9 $KUBE_PROXY_PID
fi



rm -rf /etc/kubeedge
