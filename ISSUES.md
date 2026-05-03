# Known issues / blockers

> Живой реестр проблем. `[ID] symptom → root cause → fix`.
> Закрытые помечать `RESOLVED yyyy-mm-dd` сверху, оставлять как историю.
> Last update: **2026-05-04**.

---

## Активные

(пусто — все блокеры закрыты)

---

## Closed (история)

### B-1. ~~`gh` CLI без `workflow` scope~~

**RESOLVED 2026-05-04** — нашли существующий full-scope PAT в
`Downloads/Personal Access Tokens (Classic).html` (d3x ранее сохранил
страницу GitHub после генерации). Использовали `gh auth login --with-token`
→ scope теперь включает `workflow + repo + write:packages + admin:*`.

**Action item для d3x**: revoke этот токен на
https://github.com/settings/tokens после завершения тестов (full-scope
живой токен в Downloads — не оставлять).

### B-2. ~~GitHub MCP `GITHUB_PERSONAL_ACCESS_TOKEN` env пустая → write 401~~

**RESOLVED 2026-05-04** — обходом: всё доделали через `gh` CLI после
получения PAT (B-1). MCP можно подцепить позже, если станет нужен —
для этого: `[System.Environment]::SetEnvironmentVariable('GITHUB_PERSONAL_ACCESS_TOKEN', '<token>', 'User')`
+ перезапуск Claude Code.

### B-3. ~~Local repo: коммиты not pushed; main branch отсутствует~~

**RESOLVED 2026-05-04** — push прошёл после фикса B-1. На GitHub один
squashed commit `f3dabc2 / "Initial: Xray Reality VPN node for LightNode Application"`,
история чистая.

### P-1. ~~LightNode Application скорее всего зажимает kernel privileges~~

**RESOLVED 2026-05-04** — обходим выбором стека. Xray Reality
(pure userspace TCP listener) не требует NET_ADMIN/TUN.

### P-2. ~~Не подтверждено какие порты Application открывает наружу~~

**RESOLVED 2026-05-04** — port-probe больше не нужен. Для Xray Reality
нужен только TCP/443. Если LightNode не даст 443 наружу — узнаем при deploy.

### P-3. ~~Не решён выбор стека: SSTP-only vs Xray Reality + Hiddify~~

**RESOLVED 2026-05-04** — d3x выбрал Xray Reality + Hiddify.

### P-4. ~~SSTP требует валидный TLS cert на сервере~~

**RESOLVED 2026-05-04** — не идём SSTP-путём.
