FROM postgres:9.6.3-alpine

RUN apk add --update curl wget && \
    rm -rf /var/cache/apk/* && \
    mkdir /backup && \
    mkdir /_failed

VOLUME ["/backup"]
VOLUME ["/_failed"]

ADD run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]