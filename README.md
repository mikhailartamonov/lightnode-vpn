# lightnode-vpn

Минималистичная VPN-нода под [LightNode](https://lightnode.com) Application
tier (0.1 CPU / 128 MiB / **~$0.15/мес compute**) для скрытия домашнего
IP при трафике с Windows-машины.

**Стек:** Xray VLESS+Reality на TCP/443, клиент — Hiddify Next portable.
Никаких kernel privileges на сервере не нужно.

## Зачем именно так

LightNode Application = managed runtime (как Heroku/Render). NET_ADMIN /
/dev/net/tun платформа отбирает, поэтому IKEv2/L2TP/OpenVPN/WireGuard —
сервер-сайд лежат. Xray Reality — pure userspace TCP-listener, ему не
надо никаких kernel-вещей. На клиенте Hiddify Next делает TUN-режим
прозрачно (всё работает как обычный VPN, kill-switch встроен).

## Структура

```
.github/workflows/build.yml      — build → push в ghcr.io + render setup-windows.ps1
vpn-xray/
  ├── Dockerfile                 — alpine + xray-core static
  ├── entrypoint.sh              — env-driven, ругается если нет креденшелов
  ├── config.template.json       — VLESS Reality TCP/443
  └── setup-windows.ps1.template — Win-installer (Hiddify + Firewall kill-switch)
STATUS.md                        — живой план + решения
ISSUES.md                        — реестр блокеров
LICENSE                          — MIT
```

В исходниках **нет** ни UUID/private_key/public_key/short_id, ни IP.
Всё — через GH Actions Secrets / Variables.

## Setup в GitHub

### Secrets (`Settings → Secrets and variables → Actions → Secrets`)

| Secret | Значение |
|---|---|
| `XRAY_UUID` | UUIDv4 пользователя |
| `XRAY_PRIVATE_KEY` | x25519 private (Reality), URL-safe base64 без `=` |
| `XRAY_PUBLIC_KEY` | x25519 public (parный к private) |
| `XRAY_SHORT_ID` | 8 hex символов |

Сгенерировать локально:
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

### Variables (`Settings → Secrets and variables → Actions → Variables`)

| Variable | Когда задавать | Что |
|---|---|---|
| `PUBLIC_IP` | после первого деплоя | IP, который выдаст LightNode — для рендера setup-windows.ps1 |
| `REALITY_DEST` | (опционально) | mimicry-таргет, default `www.cloudflare.com` |
| `REALITY_SNI` | (опционально) | TLS SNI клиента, default = REALITY_DEST |

## Workflow

`Push в main` или `Run workflow` → ghcr.io получает:

```
ghcr.io/<owner>/lightnode-xray:latest
ghcr.io/<owner>/lightnode-xray:<sha>
```

Если `PUBLIC_IP` задан в Variables → рендерится artifact `setup-windows.ps1`
со страницы workflow run — в нём весь Win-installer с уже подставленным IP.

## Деплой в LightNode

1. console.lightnode.com → Deploy New App
2. Image: `ghcr.io/<owner>/lightnode-xray:latest`
3. Resources: 0.1 CPU / 128 MiB
4. Port: TCP 443
5. Environment (опционально): `PUBLIC_IP=<тот же IP, выданный LightNode>` — иначе entrypoint автодетектит через api.ipify.org
6. Запусти. Готово.

В логах появится:
```
vless://<UUID>@<IP>:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=...&pbk=...&sid=...&type=tcp
```

## Использование на Windows

1. Скачай artifact `setup-windows.ps1` из последнего GH Actions run.
2. PowerShell **от Администратора**:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\setup-windows.ps1
   ```
3. Скрипт:
   - скачивает Hiddify Next portable .zip из последнего release
   - распаковывает в `%USERPROFILE%\hiddify-next\`
   - копирует vless link в буфер
   - выключает IPv6 + лочит DNS на 1.1.1.1/9.9.9.9
   - создаёт Windows Firewall kill-switch (off by default)
4. Запусти `Hiddify-Next.exe` → Profiles → Add Profile from Clipboard → Connect
5. Включи **TUN mode** в Hiddify Settings → теперь весь трафик идёт через ноду.
6. (опционально) В PowerShell: `Enable-KillSwitch` — жёсткая защита если Hiddify упадёт.

## Что критично для privacy

- **TUN mode в Hiddify** = full-tunnel, все приложения через VPN
- **IPv6 disable** = иначе IPv6 утечёт мимо Reality (он только IPv4)
- **DNS lock на 1.1.1.1** = чтобы DNS не уходил локальному провайдеру
- **Win Firewall kill-switch** = страховка если Hiddify TUN-интерфейс упадёт

## Rotate ключей

1. Перегенерь UUID + x25519 + short_id (см. секцию Secrets выше).
2. Обнови `XRAY_*` secrets в GH.
3. Run workflow → новый образ + новый setup-windows.ps1.
4. Pull latest image в LightNode UI / restart App.
5. Запусти новый `setup-windows.ps1` на Windows — старый профиль в Hiddify
   стрёт и заменит.
