FROM alpine:latest

MAINTAINER lux


ARG RPC_USER
ARG RPC_PASSW


VOLUME /media/done /torrents

EXPOSE 51413/tcp 9091/tcp


RUN apk --no-cache add transmission-daemon transmission-cli
RUN mkdir -p /media/downloading /transmission/conf.d
COPY ./settings.json /transmission/conf.d
RUN sed -i "s,\$RPC_USER,${RPC_USER}," /transmission/conf.d/settings.json && sed -i "s,\$RPC_PASSW,${RPC_PASSW}," /transmission/conf.d/settings.json
COPY ./start.sh /


CMD ./start.sh