FROM alpine:3.11

RUN apk --no-cache add bash iproute2 nginx-mod-http-lua

# Delete default config
RUN rm -r /etc/nginx/conf.d && rm /etc/nginx/nginx.conf

# Add nginx config
ADD ./nginx.conf /etc/nginx/nginx.conf

# Add collector
ADD ./collect.sh /

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN adduser -D -g 'www' www && \
    chown -R www:www /var/lib/nginx && \
    mkdir -p /run/nginx && chown -R www:www /run/nginx

USER www:www

EXPOSE 9090

CMD ["nginx", "-g", "daemon off;"]
