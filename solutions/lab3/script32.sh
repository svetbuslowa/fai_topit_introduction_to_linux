#!/bin/bash
while true; do
    echo "$(date) | PID: $$ | PPID: $PPID" >> ~/script32.log
    sleep 2
done
