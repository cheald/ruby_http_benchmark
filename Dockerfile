FROM nginx:alpine
RUN head -c 1k </dev/urandom > /usr/share/nginx/html/1k.bin && \
    head -c 10k </dev/urandom > /usr/share/nginx/html/10k.bin && \
    head -c 100k </dev/urandom > /usr/share/nginx/html/100k.bin && \
    head -c 1000k </dev/urandom > /usr/share/nginx/html/1000k.bin && \
    head -c 10000k </dev/urandom > /usr/share/nginx/html/10000k.bin && \
    gzip -k /usr/share/nginx/html/*.bin
ADD ./docker/nginx.conf /etc/nginx/conf.d/default.conf