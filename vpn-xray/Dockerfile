FROM alpine:3.20

ARG XRAY_VERSION=1.8.24
ARG TARGETARCH=amd64

RUN apk add --no-cache curl ca-certificates unzip tini \
 && case "${TARGETARCH}" in \
      amd64) X="64" ;; \
      arm64) X="arm64-v8a" ;; \
      *) echo "unsupported arch ${TARGETARCH}"; exit 1 ;; \
    esac \
 && curl -fL "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${X}.zip" -o /tmp/x.zip \
 && unzip -j /tmp/x.zip xray -d /usr/local/bin \
 && unzip -j /tmp/x.zip 'geoip.dat' 'geosite.dat' -d /usr/local/share/xray 2>/dev/null || true \
 && rm /tmp/x.zip \
 && chmod +x /usr/local/bin/xray \
 && apk del curl unzip

# Все секреты — только через ARG из CI Secrets, литералов нет
ARG XRAY_UUID
ARG XRAY_PRIVATE_KEY
ARG XRAY_PUBLIC_KEY
ARG XRAY_SHORT_ID
ARG REALITY_DEST=www.cloudflare.com
ARG REALITY_SNI=www.cloudflare.com

ENV XRAY_UUID=${XRAY_UUID}
ENV XRAY_PRIVATE_KEY=${XRAY_PRIVATE_KEY}
ENV XRAY_PUBLIC_KEY=${XRAY_PUBLIC_KEY}
ENV XRAY_SHORT_ID=${XRAY_SHORT_ID}
ENV REALITY_DEST=${REALITY_DEST}
ENV REALITY_SNI=${REALITY_SNI}

COPY entrypoint.sh /entrypoint.sh
COPY config.template.json /config.template.json
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
