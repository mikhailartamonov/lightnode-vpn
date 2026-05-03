# Known issues / blockers

> Живой реестр проблем. `[ID] symptom → root cause → fix`.
> Закрытые помечать `RESOLVED yyyy-mm-dd` сверху, оставлять как историю.
> Last update: **2026-05-04**.

---

## Активные

### P-5. LightNode Application tier **не** принимает custom Docker images

**Symptom.** Все попытки деплоя `ghcr.io/mikhailartamonov/lightnode-xray:latest`
через UI ведут либо к curated app store (10 фикс. apps, $0.15-1.62/мес),
либо к VPS-deploy ($7.7/мес min), либо к Discord-Bot scaffold (требует свой
Python/JS код, не Docker).

**Discovered 2026-05-04** через Playwright UI exploration:

- App Store top: Discord-Bot, Hermes-Agent, MinIO, OpenClaw, IT-Tools,
  N8N, Open-WebUI, OpenList, UptimeKuma, WordPress — все фикс., нет «Custom Docker»
- «More Application Image» (Docker / WireGuard / Tailscale / etc.) кликом ведёт на
  VPS create form: type CPU Shared from $7.7/мес, type GPU Exclusive выше
- Discord-Bot Application Service принимает **код** (requirements.txt /
  package.json) на Python/Java/NodeJS/Bun + ваш bot token. Не Docker image.
  Кроме того inbound TCP не пробрасывается (он outbound websocket к Discord).
- Минимальный `0.1 Core / 128 MiB / 1 GiB` тариф **исключительно** для IT-Tools
  ($0.000203/h ≈ $0.15/мес). IT-Tools = web util toolbox, не наш use-case.

**Root cause.** LightNode Application = PaaS-стиль, не «container as a service».
Нет API/UI для ввода произвольного registry URL. Custom Docker = только VPS.

**Fix variants.**

1. **LightNode Cloud VPS $7.7/мес** — full Docker, наш image работает as-is.
   Установка: deploy VPS Bangkok 1vCPU/2GB → SSH → `docker run --restart=always -p 443:443 ghcr.io/mikhailartamonov/lightnode-xray:latest`. Месячный счёт $7.7 (без bandwidth surprise если <1TB).
2. **Vultr $2.50/мес** — full Docker, своё API. Бюджет $2-3 укладывается
   но новый аккаунт + ключи. У нас тулз `~/lightnode/` для них нет.
3. **Использовать pre-built LightNode WireGuard / OpenVPN из «More Application
   Image»** — на VPS, по факту тот же $7.7+/мес, но без своего custom image.
   Туннель готовый. Client-сторона — официальный WireGuard.exe для Windows
   с kill-switch галкой.

**Pending решение d3x.** Бюджет $2-3 формально превышается на LightNode-only;
если флекс до $7.7 — V1, если строго $2-3 → V2 (Vultr).

### B-4. Playwright Chrome session гибнет при killproc для разлочки lockfile

**Symptom.** При попытке открыть LightNode UI через Playwright MCP получаем
`Browser is already in use for ...mcp-chrome-5cd6ba1`. После kill процесса +
remove lockfile + retry — login session слетает (cookies в profile теряются).
В итоге пользователю приходится перевводить пароль каждый раз.

**Root cause.** Multiple Playwright MCP server instances в системе (по одному
на сессию Claude Code) shareят один profile dir и racят за блокировку.

**Workaround.** Не убивать chrome лишний раз; делать всё в одной сессии без
рестартов. Если уже убили — пользователь логинится заново руками в playwright-окне.

**Fix proper.** В Playwright MCP config поставить `--isolated` чтобы каждая
сессия имела свой profile. Или явно указать unique `--user-data-dir` per session.

---

## Closed (история)

### B-1. ~~`gh` CLI без `workflow` scope~~

**RESOLVED 2026-05-04** — нашли существующий full-scope PAT в Downloads.

**Action item для d3x**: revoke этот токен на https://github.com/settings/tokens.

### B-2. ~~GitHub MCP `GITHUB_PERSONAL_ACCESS_TOKEN` env пустая → write 401~~

**RESOLVED 2026-05-04** — обходом через `gh` CLI.

### B-3. ~~Local repo: коммиты not pushed; main branch отсутствует~~

**RESOLVED 2026-05-04** — push прошёл, single commit `f3dabc2`.

### P-1. ~~LightNode Application скорее всего зажимает kernel privileges~~

**SUPERSEDED by P-5** — выяснили что Application вообще не принимает
custom Docker. Пункт про NET_ADMIN неактуален — мы туда не доберёмся.

### P-2. ~~Не подтверждено какие порты Application открывает наружу~~

**SUPERSEDED by P-5** — Application не наш кейс.

### P-3. ~~Не решён выбор стека: SSTP-only vs Xray Reality + Hiddify~~

**RESOLVED 2026-05-04** — выбран Xray Reality + Hiddify, образ собран.
P-5 теперь блокирует deploy этого образа.

### P-4. ~~SSTP требует валидный TLS cert на сервере~~

**RESOLVED 2026-05-04** — не идём SSTP-путём.
