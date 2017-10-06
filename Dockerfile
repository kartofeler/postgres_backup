FROM postgres:9.6.3

RUN apt-get update && \
    apt-get install -y wget curl netcat cron && \
    mkdir /backup

ADD run.sh /run.sh
RUN chmod +x /run.sh
VOLUME ["/backup"]

CMD ["/run.sh"]