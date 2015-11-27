FROM nginx:1.9.7

RUN apt-get update && \
    apt-get install -q -y ruby && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf.erb /nginx.conf.erb
COPY entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
