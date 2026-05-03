# vpn-xray

Single-protocol VPN-нода: **Xray VLESS+Reality** на TCP/443. Pure userspace
— ни NET_ADMIN, ни /dev/net/tun на сервере не нужны → летит на самом
зажатом managed-контейнере (LightNode Application 0.1 CPU / 128 MiB).

Клиент Windows: **Hiddify Next** portable (~3 MB .zip, без admin install,
TUN-mode + kill-switch встроенные).

## Build args (приходят из CI Secrets, литералов нет)

| arg | назначение |
|---|---|
| `XRAY_UUID` | UUIDv4 пользователя VLESS |
| `XRAY_PRIVATE_KEY` | x25519 private (Reality) |
| `XRAY_PUBLIC_KEY` | x25519 public (нужен в client share-link) |
| `XRAY_SHORT_ID` | short_id (8 hex chars) |
| `REALITY_DEST` | mimicry-таргет, default `www.cloudflare.com` |
| `REALITY_SNI` | TLS SNI клиента, default = REALITY_DEST |

Сгенерировать новые значения:
```sh
python -c "import uuid, secrets, base64
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
from cryptography.hazmat.primitives import serialization
priv = X25519PrivateKey.generate()
pb = priv.private_bytes(serialization.Encoding.Raw, serialization.PrivateFormat.Raw, serialization.NoEncryption())
qb = priv.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
print('UUID=' + str(uuid.uuid4()))
print('PRIV=' + base64.urlsafe_b64encode(pb).decode().rstrip('='))
print('PUB='  + base64.urlsafe_b64encode(qb).decode().rstrip('='))
print('SID='  + secrets.token_hex(4))"
```

## Runtime env

| env | default | что делает |
|---|---|---|
| `PUBLIC_IP` | auto-detect (api.ipify.org) | IP в client share-link |

## Локальная сборка (dev)

```sh
docker build \
  --build-arg XRAY_UUID=$(uuidgen) \
  --build-arg XRAY_PRIVATE_KEY=...  \
  --build-arg XRAY_PUBLIC_KEY=...   \
  --build-arg XRAY_SHORT_ID=$(openssl rand -hex 4) \
  -t vpn-xray:dev .
docker run --rm -p 4443:443 vpn-xray:dev
```

В логах появится `vless://...` link для клиента.

## Что внутри

- `Dockerfile` — alpine 3.20 + xray-core static binary (~25MB финал)
- `entrypoint.sh` — рендерит config.template.json из env, валидирует наличие всех ключей, exec xray
- `config.template.json` — VLESS Reality TCP/443, IPv4-only, block private nets
- `setup-windows.ps1.template` — render-job в CI подставляет PUBLIC_IP + ключи и кладёт в artifact

## Порты

| proto | port |
|---|---|
| VLESS Reality (TLS-mimicry) | TCP 443 |

Один порт. Если LightNode Application даёт хоть TCP 443 наружу (а это даёт
почти любая managed-app платформа) — работает.
