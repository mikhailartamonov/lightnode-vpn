# Known issues / blockers

> Живой реестр проблем. Каждая запись — `[ID] symptom → root cause → workaround/fix`.
> Закрытые помечать `RESOLVED yyyy-mm-dd` сверху, оставлять как историю.
> Last update: **2026-05-04**.

---

## Активные

### B-1. `gh` CLI без `workflow` scope → push с `.github/workflows/*.yml` отбивается

**Symptom.**
```
remote rejected: refusing to allow an OAuth App to create or update workflow
.github/workflows/build.yml without `workflow` scope
```

**Root cause.** Текущий keyring-токен `gh` имеет scopes `gist, read:org, repo`
— не хватает `workflow` для push'а workflow-файлов.

**Fix.**
1. Запустить `gh auth refresh -h github.com -s workflow` (cmd-окно открыто
   через PowerShell `Start-Process`), авторизовать в браузере.
2. После refresh — push пройдёт.

### B-2. GitHub MCP `GITHUB_PERSONAL_ACCESS_TOKEN` env не установлена → write 401

**Symptom.** `mcp__github__create_or_update_file` возвращает
`Authentication Failed: Requires authentication`.

**Root cause.**
`~/.claude/plugins/cache/claude-plugins-official/github/unknown/.mcp.json`
содержит `Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}`. В user-env
эта переменная **не задана** (`echo $GITHUB_PERSONAL_ACCESS_TOKEN` → пусто).
MCP шлёт буквальную строку, GitHub Copilot MCP gateway возвращает 401.

**Fix.**
1. После `gh auth refresh -s workflow` (см. B-1):
   ```
   gh auth token
   ```
   Скопировать токен.
2. Поставить в Windows user-env:
   ```powershell
   [System.Environment]::SetEnvironmentVariable(
       'GITHUB_PERSONAL_ACCESS_TOKEN', '<token>', 'User')
   ```
3. Полностью перезапустить Claude Code (MCP подцепляет env при старте).

После этого MCP сможет push/secrets/visibility-change без `gh`.

**Альтернатива:** жить с `gh` CLI — после фикса B-1 этого хватает.

### B-3. Local repo: коммиты not pushed; main branch на GitHub отсутствует

**Symptom.** `mikhailartamonov/lightnode-vpn` создан (через `gh repo create`),
но push отбился (см. B-1) → на GitHub main-ветки нет.

**Workaround.** Снимется автоматически после фикса B-1.

---

## Closed (история)

### P-1. ~~LightNode Application скорее всего зажимает kernel privileges~~

**RESOLVED 2026-05-04** — обходим выбором стека.

Был блокер для IKEv2/L2TP/OpenVPN/WireGuard server-side. Решили
использовать Xray Reality (pure userspace TCP listener) — kernel
privileges на сервере не нужны. Application 0.1 CPU / 128 MiB tier
держит образ ~50 MB RAM в idle.

### P-2. ~~Не подтверждено какие порты Application открывает наружу~~

**RESOLVED 2026-05-04** — port-probe больше не нужен.

Для Xray Reality нужен только TCP/443, а это даёт любая managed-app-платформа.
Если LightNode не даст наружу даже 443 (что крайне маловероятно для product
позиционируемого как app-hosting) — будем знать на этапе deploy.

`port-probe/` директория удалена из репо (была в коммите `0252ba7`,
осталось в reflog).

### P-3. ~~Не решён выбор стека: SSTP-only vs Xray Reality + Hiddify~~

**RESOLVED 2026-05-04** — d3x выбрал Xray Reality + Hiddify.

### P-4. ~~SSTP требует валидный TLS cert на сервере~~

**RESOLVED 2026-05-04** — не идём SSTP-путём.
