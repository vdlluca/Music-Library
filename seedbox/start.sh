#!/bin/sh

find torrents -name "*.added" | sed -E "s,(.*).added,mv \"&\" \"\1\"," | sh
rm -rf /transmission/conf.d/resume /transmission/conf.d/torrents

transmission-daemon -g /transmission/conf.d -f