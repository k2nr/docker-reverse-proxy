FROM nginx:1.9.7

RUN apt-get update && \
    apt-get install -q -y ruby && \
    rm -rf /var/lib/apt/lists/* && \
    gem install aws-sdk && \
    mkdir -p /etc/nginx/certs

ADD templates /templates
COPY entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
