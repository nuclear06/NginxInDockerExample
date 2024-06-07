FROM nginx:alpine AS builder

ENV MODULES_PATH=/usr/modules

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \  
  apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev \ 
  git 


RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \  
  NGINX_VERSION=$(nginx -V 2>&1| grep version | sed -n -e "s/^.*nginx\///p") && \   
  CONFARGS=${CONFARGS/-fstack-clash-protection/} && \ 
  curl "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
  git clone http://github.com/vozlt/nginx-module-vts.git ${MODULES_PATH}/nginx-module-vts && \
  git clone http://github.com/vozlt/nginx-module-sts.git ${MODULES_PATH}/nginx-module-sts && \
  git clone http://github.com/vozlt/nginx-module-stream-sts.git ${MODULES_PATH}/nginx-module-stream-sts && \
  mkdir -p /usr/src && \
  mkdir -p /usr/modules && \
  tar -zxC /usr/src -f nginx.tar.gz && \
  cd /usr/src/nginx-${NGINX_VERSION} && \
  ./configure --with-compat "$CONFARGS" --with-stream --add-dynamic-module=${MODULES_PATH}/nginx-module-vts \
  --add-dynamic-module=${MODULES_PATH}/nginx-module-sts \
  --add-dynamic-module=${MODULES_PATH}/nginx-module-stream-sts && \
  make modules && \
  mv ./objs/*.so /

FROM nginx:alpine
COPY --from=builder /*.so /etc/nginx/modules/
EXPOSE 80
STOPSIGNAL SIGTERM