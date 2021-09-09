FROM ubuntu:latest

MAINTAINER lux


ARG RPC_USER
ARG RPC_PASSW


VOLUME /media /torrents

EXPOSE 51413/tcp 9091/tcp


RUN apt update && apt install -y transmission-daemon transmission-cli

COPY ./settings.json /etc/transmission-daemon/

RUN mkdir -p $MEDIA_DIR/{downloading,done}

RUN sed -i "s,\$RPC_USER,${RPC_USER}," /etc/transmission-daemon/settings.json && sed -i "s,\$RPC_PASSW,${RPC_PASSW}," /etc/transmission-daemon/settings.json


CMD transmission-daemon -g /etc/transmission-daemon -f