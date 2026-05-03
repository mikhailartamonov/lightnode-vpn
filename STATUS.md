# Status — lightnode-vpn

> Живой журнал что делаем, какие решения приняты, что висит.
> Обновлять при каждом изменении направления или вылезшем блокере.

Last update: **2026-05-04**.

---

## Цель

VPN-нода на тарифе LightNode Application 0.1 CPU / 128 MiB / **~$0.15-2/мес**,
для скрытия домашнего IP при трафике с **Windows-машины** (d3x).

## Принятый стек (2026-05-04)

**Xray VLESS+Reality** (TCP/443) + **Hiddify Next portable** на винде.

Почему так:
- Pure userspace — не нужны NET_ADMIN / /dev/net/tun на сервере (закрывает P-1)
- Один порт TCP/443, выглядит как HTTPS к cloudflare.com — пройдёт через
  любую managed-app-платформу, у которой есть наружный 443
- Hiddify Next: zip 3 MB без admin-install; TUN-mode + kill-switch встроенные
  → клиент-сторона без cert-возни и без сторонних сертификатов
- Бюджет $0.15-2/мес держится; обходим переход на ECS ($8.7+/мес)

Альтернативы рассмотрены и **отклонены**:
- ECS LightNode + IKEv2/strongSwan ($8.7/мес) — превышает бюджет
- Vultr ECS + IKEv2 ($2.50/мес) — оставаться на LightNode по решению d3x
- SoftEther multi-protocol — overkill, P-1 ломает половину
- SSTP (Win native dropdown) — cert-import возня; хочется чище

## План в шагах

| # | Шаг | Статус |
|---|---|---|
| 1 | Repo `mikhailartamonov/lightnode-vpn` локально, без хардкода | ✅ |
| 2 | Refactor: выкинуть SoftEther + port-probe, добавить vpn-xray | ✅ done 2026-05-04 |
| 3 | GH Actions workflow: build → ghcr.io + render setup-windows.ps1 | ✅ |
| 4 | Локальный smoke-test Xray-образа (74.3 MB, Xray 1.8.24 OK) | ✅ |
| 5 | Push в GitHub | ⏳ блокер B-1 (gh `workflow` scope) |
| 6 | Сделать репо public | ⏳ |
| 7 | Установить GitHub Secrets `XRAY_UUID/PRIVATE_KEY/PUBLIC_KEY/SHORT_ID` | ⏳ |
| 8 | Запустить workflow → ghcr.io получает `lightnode-xray:latest` | ⏳ |
| 9 | Деплой контейнера в LightNode Application UI (image + 0.1 CPU + 443) | ⏳ ручной шаг d3x |
| 10 | Записать выданный IP в Variable `PUBLIC_IP` → re-run workflow → setup-windows.ps1 artifact | ⏳ |
| 11 | На винде запустить setup-windows.ps1 от админа → Hiddify + kill-switch | ⏳ |
| 12 | Проверить что трафик уходит через ноду (whatsmyip и т.д.) | ⏳ |

## Артефакты на диске

- `~/projects/lightnode-vpn/` — repo (3 локальных коммита, не запушены)
- `~/projects/lightnode-vpn/vpn-xray/` — образ
- `~/projects/lightnode-vpn/.github/workflows/build.yml` — pipeline
- `~/projects/lightnode-vpn/vpn-xray/.secrets` — копия Xray-ключей (gitignored, для ротации)
- `~/projects/lightnode-vpn/STATUS.md` (этот файл) и `ISSUES.md`
- `~/lightnode/vpn-app/` — старый VLESS-attempt (legacy, не в репо, можно стереть)
- `~/lightnode/vpn-softether/` — выкинутый SoftEther-attempt (legacy, не в репо)

## Ключи Xray (живут в .secrets, нужно завести в GH Secrets)

См. `~/projects/lightnode-vpn/vpn-xray/.secrets` (gitignored).

## Известные проблемы / блокеры

См. **ISSUES.md**.

## Открытые вопросы (от d3x)

- Большие планы на ноду — обещал прислать список вопросов. Пока не было.
