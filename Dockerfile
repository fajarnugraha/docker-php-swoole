ARG DIST=ubuntu:20.04
ARG OS_DATE=201222
FROM $DIST AS base
RUN echo $OS_DATE && apt update && apt -y dist-upgrade && apt -y install php-cli php-curl php-mysql curl && rm -rf /var/cache/apt/* /var/lib/apt/*

FROM base as builder
WORKDIR /data/src/swoole
RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt -y install php-dev build-essential && apt clean
ARG SWOOLE_VERSION=4.5.9
RUN pecl download swoole-$SWOOLE_VERSION
RUN tar xvfz swoole-$SWOOLE_VERSION.tgz
WORKDIR /data/src/swoole/swoole-$SWOOLE_VERSION
RUN phpize
RUN ./configure --enable-openssl --enable-http2 --enable-mysqlnd
RUN nice -n +19 make -j$(nproc)
RUN strip modules/swoole.so

FROM base
WORKDIR /app
CMD ["/usr/bin/php", "server.php"]  
COPY --from=builder /data/src/swoole/swoole-*/modules/swoole.so .
ARG PORT=8080
EXPOSE $PORT
ARG COMMIT=e67ce61
RUN export PHP_VERSION=$(basename $(ls -d1 /etc/php/*.*)) && mv swoole.so /usr/lib/php/2*/ && echo extension=swoole.so > /etc/php/$PHP_VERSION/mods-available/swoole.ini && ln -s /etc/php/$PHP_VERSION/mods-available/swoole.ini /etc/php/$PHP_VERSION/cli/conf.d/90-swoole.ini && curl -o server.php https://raw.githubusercontent.com/fajarnugraha/php-loadtest-app/$COMMIT/index.php && sed -i "s/9501/$PORT/" server.php && useradd -g 0 -d /app user && chown -R user:root /app && chmod 771 /app
