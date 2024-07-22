#!/bin/bash

KUBE_PROXY_PID=$(pgrep -f kube-proxy)
MQTT_PROXY_PID=$(pgrep -f mosquitto)

if [ -n "$KUBE_PROXY_PID" ]; then
  kill -9 $KUBE_PROXY_PID
fi

if [ -n "$MQTT_PROXY_PID" ]; then
  kill -9 $MQTT_PROXY_PID
fi

systemctl stop edgecore
rm -rf /etc/kubeedge
rm -rf /etc/systemd/system/edgecore.service 
systemctl daemon-reload 
