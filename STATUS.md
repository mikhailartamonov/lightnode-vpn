# Status — lightnode-vpn

> Живой журнал что делаем, какие решения приняты, что висит.
> Обновлять при каждом изменении направления или вылезшем блокере.

Last update: **2026-05-04**.

---

## Цель

VPN-нода на тарифе LightNode Application 0.1 CPU / 128 MiB / **~$0.15-2/мес**,
для скрытия домашнего IP при трафике с **Windows-машины** (d3x).

## Принятый стек

**Xray VLESS+Reality** (TCP/443) + **Hiddify Next portable** на винде.
Pure userspace на сервере (нет требований kernel privileges); клиент с
TUN-mode и kill-switch встроенными.

## План в шагах

| # | Шаг | Статус |
|---|---|---|
| 1 | Repo `mikhailartamonov/lightnode-vpn` локально, без хардкода | ✅ |
| 2 | Refactor: выкинуть SoftEther + port-probe, добавить vpn-xray | ✅ |
| 3 | GH Actions workflow: build → ghcr.io + render setup-windows.ps1 | ✅ |
| 4 | Локальный smoke-test Xray-образа (74.3 MB, Xray 1.8.24 OK) | ✅ |
| 5 | Push в GitHub | ✅ 2026-05-04 (один squashed commit `f3dabc2`/`Initial: Xray Reality VPN node`) |
| 6 | Сделать репо public | ✅ |
| 7 | Установить GitHub Secrets `XRAY_UUID/PRIVATE_KEY/PUBLIC_KEY/SHORT_ID` | ✅ |
| 8 | Запустить workflow → ghcr.io получает `lightnode-xray:latest` | ✅ build прошёл за 25s, image **public** |
| 9 | ~~Деплой контейнера в LightNode Application UI~~ | ❌ **blocked by P-5** — Application не принимает custom Docker. Нужен другой target. См. ISSUES.md и блок ниже. |
| 10 | Записать выданный IP в Variable `PUBLIC_IP` → re-run workflow → setup-windows.ps1 artifact | ⏳ |
| 11 | На винде запустить setup-windows.ps1 от админа → Hiddify + kill-switch | ⏳ |
| 12 | Проверить что трафик уходит через ноду (whatsmyip и т.д.) | ⏳ |
| 13 | **Revoke** временного PAT (ghp_xL0Nh7Zv…) на https://github.com/settings/tokens | ⏳ ручной шаг d3x |

## Артефакты

| Где | Что |
|---|---|
| https://github.com/mikhailartamonov/lightnode-vpn | source, public |
| `ghcr.io/mikhailartamonov/lightnode-xray:latest` | image, public, ~74 MB |
| `~/projects/lightnode-vpn/` | local checkout |
| `~/projects/lightnode-vpn/vpn-xray/.secrets` | копия Xray-ключей (gitignored) |
| `~/Downloads/Personal Access Tokens (Classic).html` | сохранённая страница PAT (содержит токен в plaintext, **не удалять пока d3x сам не разберётся**) |

## Команды чтобы сдвинуть последние шаги

После деплоя в LightNode UI и получения IP:

```sh
# Шаг 10 — задать переменную и пересобрать
gh variable set PUBLIC_IP --body '<LIGHTNODE_IP>' --repo mikhailartamonov/lightnode-vpn
gh workflow run build.yml --repo mikhailartamonov/lightnode-vpn

# дождаться завершения, скачать artifact
gh run download --repo mikhailartamonov/lightnode-vpn --name setup-windows --dir ~/Downloads/

# Шаг 11 — на винде (PowerShell от Админа)
Set-ExecutionPolicy -Scope Process Bypass
~/Downloads/setup-windows.ps1
```

## Известные проблемы

См. **ISSUES.md**. Активно: P-5 (Application не принимает custom Docker), B-4
(Playwright session гибнет при ребуте). Закрыто: B-1..B-3, P-1..P-4.

## Развилка по target hosting (2026-05-04)

Application tier за $0.15/мес — мираж. Реальные пути:

| # | Target | Цена/мес | Плюсы | Минусы |
|---|---|---|---|---|
| 1 | LightNode VPS Bangkok (1vCPU/2GB) | **$7.7** | один провайдер, наш образ работает as-is, тулз в `~/lightnode/` остаётся | бюджет $2-3 нарушен |
| 2 | Vultr Tokyo/SG/FRA (1vCPU/512MB) | **$2.50** | бюджет ОК, full Docker | новый акк + новые тулз |
| 3 | LightNode pre-built WireGuard на VPS | $7.7 | один-клик деплой, не нужен наш custom образ | свой образ Xray не используется |

Жду от d3x явного выбора. По умолчанию рекомендую **#1**: проще всего здесь
и сейчас (баланса хватит на месяц), потом можно мигрировать если бюджет
останется $2-3 надолго.

## Открытые вопросы

- d3x обещал «большие планы на ноду + список вопросов». Пока не было.
