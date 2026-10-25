# Invite code deployment and verification

## Rules

- One persistent 12-character code per `citizenid`; one successful redemption, immutable.
- New redemptions require current total Playtime <= 18,000 seconds (exactly 5 hours allowed), checked server-side including unsaved session time and VIP-added hours. Missing Playtime data blocks redemption until it can be checked. Existing redemptions remain intact; this entry limit is separate from the 50-hour qualification timer.
- 180,000 online seconds after redemption, including AFK; no historical, offline or VIP-added playtime.
- Matching license or at least two distinct player tokens rejects duplicate participation. No IP collection/check.
- Missing current identity data defers eligibility; fingerprints are stored as SHA-256 hashes and retained across sessions.
- First 50 verified referrals per owner receive 50 Coin (invitee) and 100 Coin (inviter). Redemption does not reserve a slot. After the cap, explicit confirmation is required to redeem without rewards for either party.
- Additional milestone bonuses: 5=250, 10=600, 20=1,500, 30=2,500, 50=5,000. Milestones count currently valid referrals, including valid referrals outside the base-reward cap. Total inviter rewards cannot exceed 14,850 Coin.
- Late fraud removes valid credit but does not reverse Coin, refund a consumed slot or allow a milestone to be paid twice. Admin reversal requires identity checks again.

## Installation

1. Back up existing invite tables and `players.citizenid`/`players.coin` before applying a migration. `tools/invite_code.sql` is the initial additive migration, not an upgrade for a different invite schema. Do not import legacy V: invite tables over this schema.
2. Execute `tools/invite_code.sql` against the database configured by FXServer. It does not modify `players` or any existing Coin balances. The module refuses to initialize if required tables/Coin columns are absent.
3. Build in `web` with `npm run build`. The restored embedded-module sources are versioned under `web/vendor`; see `web/vendor/sources.json` for origins and hashes. Build output is the `web/build` used by the manifest.
4. Start FXServer normally, or run `restart Tipi_menu` in its console if it is already running. This resource depends on `qbx_core`, `oxmysql` and `ox_lib`.
5. Give only the intended admin principal the ACE `command.invitefraud`. Example: `add_ace group.admin command.invitefraud allow`. Server console may always use the command.

Command: `invitefraud <citizenid> <on|off> <reason>` (reason required, at most 512 bytes).

Startup diagnostics: run `invitestatus` in the server console (in-game access requires `command.invitestatus`). It prints readiness, startup stage, actual resource path and the last initialization error. Initialization retries every 30 seconds and logs the specific failure when it changes. Stages are `database` (connection), `store` (missing Lua helper), `schema` (invite migration) and `coin` (Coin configuration/storage engine). Apply migration to the database used by the running server, which may differ from this workstation's configuration. Successful initialization logs `Ready: database checks passed.`

The initial migration was applied on 2026-10-26. Backup: `X:\UDSFxServer\backups\tipi-invite-20261026-004704`. Seven empty invite tables were created; all 2,996 player Coin rows matched the pre-migration snapshot. FXServer/FiveM were not running, so live verification and resource startup remain pending.

Validation on this checkout: production TypeScript/Vite build passed, 16 MariaDB/Lua integration groups passed (including actual OnReady failure/recovery), and browser tests against the built production assets passed at 1280×720, 1366×768 and 1920×1080. Build warnings were limited to the existing npm config, outdated Browserslist data and a bundle exceeding 500 kB. The source copies in `web/vendor` match all 55 originals by SHA-256.

## Interfaces and failure handling

NUI callbacks `inviteCode:getState` and `inviteCode:redeem` forward to `Tipi_menu:sv:invite:getState` and `Tipi_menu:sv:invite:redeem`.

`redeem` accepts a code string or `{ code, confirmExhausted }`; `confirmExhausted` must be true only after the explicit exhausted-cap UI confirmation. Responses use `{ ok, message }`; an exhausted-cap rejection additionally sets `needsExhaustedConfirmation`. Successful responses include the complete state. Server source determines identity; no client-supplied ID, time, count or Coin amount is accepted.

State includes own code, blocked flag, reward configuration, referral counts, paid-slot usage, lifetime Coin, milestone status and the optional redeemed-code progress. Redemption status: `pending`, `verification`, `rejected`, `processing`, `qualified`, `exhausted`. No identity fingerprints or fraud matching details are exposed.

Identity/redemption/payout changes share a database row lock; owner payout rows are also locked. Standard oxmysql transactions atomically persist payout slots, the reward ledger and Coin increments. Failed transactions retry; unique keys prevent duplicate claims. Checkpoints use cumulative per-session seconds, so a lost commit acknowledgement cannot double credit time. Batches hold at most 50 sessions. Completed/nonparticipant sessions are cached to avoid polling their redemption rows repeatedly.

Checkpoints run every 30 seconds plus unload/disconnect. Shutdown flush is best effort; a hard crash or unfinished asynchronous shutdown can lose time since the latest successful checkpoint. Database outages can extend that interval. No offline time is reconstructed. Historical session checkpoints are retained to make retries safe.

Fraud cases are not real-world identity proof: the license/token policy can flag legitimate shared-device use. Admin review and reversal are available; shared IP alone is never grounds for rejection.

## Automated checks

SQL/runtime harness requires Python `pymysql` and `lupa`:

```powershell
python tools/test_invite_code.py --config X:/UDSFxServer/server.cfg
```

The harness reads connection settings without printing credentials, creates a uniquely named `tipi_invite_test_*` database, executes the actual Lua-generated transactions, and drops only that test database. The connection needs permission to create/drop test databases. It tests concurrent duplicates, payout cap, rollback/retry, milestones, fraud reversal, identity readiness, oxmysql boolean compatibility, 5-hour entry boundary and live/VIP total playtime, 50-hour boundary, VIP exclusion from qualification, source reuse, reconnect and resource-instance restart.

Browser checks require Playwright and Edge (or `BROWSER_EXECUTABLE`). Start Vite or Vite preview, set `INVITE_PREVIEW_URL` to its URL and run:

```powershell
node tools/test_invite_browser.cjs
```

`PLAYWRIGHT_MODULE` may specify an externally installed Playwright package; `INVITE_SCREENSHOTS` selects the screenshot folder (defaults to the system temporary folder). Tests use mocked NUI responses, not the game or production database. They cover three viewports, clipboard, acknowledgement, exhausted-cap confirmation, immutable redemption, status displays, milestone scrolling, the above-5-hour entry lock and browser errors.

## Live acceptance still required

Use separate legitimate test identities on a staging FXServer to verify Qbox load/unload events, FiveM token collection, NUI focus/clipboard, disconnect/reconnect, actual resource restart, offline inviter payout and simultaneous players. Never lower the production 50-hour threshold to accelerate a test. Inspect `tipi_invite_reward_log`, referral states and balances after each scenario. Browser and MariaDB harness results are not multiplayer or CEF runtime proof.

To disable the feature, set `Config.EnableModules.InviteCode.enabled = false` and restart the resource. Preserve invite tables/ledger. Re-enabling must retain consumed slots and previously paid milestones.
