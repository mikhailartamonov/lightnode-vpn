#!/bin/sh
set -eu

# Все значения должны прийти ENV (из build-args в CI). Падаем громко если что-то пусто.
: "${XRAY_UUID:?XRAY_UUID is empty — build-arg / env not provided}"
: "${XRAY_PRIVATE_KEY:?XRAY_PRIVATE_KEY is empty}"
: "${XRAY_PUBLIC_KEY:?XRAY_PUBLIC_KEY is empty}"
: "${XRAY_SHORT_ID:?XRAY_SHORT_ID is empty}"

DEST="${REALITY_DEST:-www.cloudflare.com}"
SNI="${REALITY_SNI:-${DEST}}"

# Render config from template
sed \
  -e "s|__UUID__|${XRAY_UUID}|g" \
  -e "s|__DEST__|${DEST}|g" \
  -e "s|__SNI__|${SNI}|g" \
  -e "s|__PRIVATE_KEY__|${XRAY_PRIVATE_KEY}|g" \
  -e "s|__SHORT_ID__|${XRAY_SHORT_ID}|g" \
  /config.template.json > /tmp/config.json

# Detect public IP for client share link (поверх api.ipify.org)
PUBLIC_IP="${PUBLIC_IP:-$(wget -qO- https://api.ipify.org 2>/dev/null || echo SERVER_IP)}"

LINK="vless://${XRAY_UUID}@${PUBLIC_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${SNI}&fp=chrome&pbk=${XRAY_PUBLIC_KEY}&sid=${XRAY_SHORT_ID}&type=tcp&headerType=none#lightnode-${PUBLIC_IP}"

cat <<EOF >&2
==============================================================
  Xray VLESS+Reality up
  Listen: 0.0.0.0:443 TCP
  SNI mask: ${SNI}  ->  dest ${DEST}:443
  Public IP: ${PUBLIC_IP}
  UUID: ${XRAY_UUID}
  ShortID: ${XRAY_SHORT_ID}
--------------------------------------------------------------
  Client link (импорт в Hiddify Next / v2rayN / NekoBox):

  ${LINK}

==============================================================
EOF

exec /usr/local/bin/xray run -c /tmp/config.json
