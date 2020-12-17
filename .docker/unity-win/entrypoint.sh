#!/bin/bash

xvfb-run --auto-servernum --server-args='-screen 0 640x480x24' $@
    /opt/Unity/Editor/Unity -batchmode -projectPath /root/project \
    -username $UNITY_USERNAME -password $UNITY_PASSWORD -quit -nographics ""