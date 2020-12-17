#!/bin/ash

Xvfb :1 -screen 0 640x480x24 &
exec krita --nosplash "$@"