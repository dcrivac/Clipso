# Deploying the Clipso license server (Fly.io)

The app talks to `https://api.clipso.app`. This is the runbook to make that host
real. One-time setup is ~15 minutes; redeploys are `fly deploy`.

Prereqs: `flyctl` (`brew install flyctl`), a Fly.io account.

---

## 1. Authenticate

```bash
fly auth login
```

## 2. Create the app (no deploy yet)

```bash
cd backend
fly launch --no-deploy --copy-config --name clipso-license-server --region iad
```

- Keep the existing `fly.toml`.
- If the name is taken, pick another and update `app = ` in `fly.toml`.
- Decline the offer to add databases here — we do it explicitly next.

## 3. Provision Postgres

```bash
fly postgres create --name clipso-db --region iad --initial-cluster-size 1 \
  --vm-size shared-cpu-1x --volume-size 1
fly postgres attach clipso-db --app clipso-license-server
```

`attach` sets `DATABASE_URL` on the app automatically, pointing at the cluster
over Fly's private network. Our `db.js` connects with TLS off for `.flycast` /
`.internal` hosts — nothing else to configure.

> Prefer managed? Any provider works. Create the DB, then
> `fly secrets set DATABASE_URL='postgres://…?sslmode=require'` and skip the two
> commands above. `db.js` turns on TLS when it sees `sslmode=require` or
> `NODE_ENV=production`.

## 4. Set the remaining secrets

```bash
fly secrets set \
  ADMIN_TOKEN="$(openssl rand -hex 32)" \
  PADDLE_WEBHOOK_SECRET="<from Paddle → Developer Tools → Notifications>" \
  --app clipso-license-server
```

`PADDLE_WEBHOOK_SECRET` can be a placeholder until Paddle is configured — the
license activate/validate endpoints and `generate-license.js` don't need it.
Only `POST /webhook/paddle` does.

Save the `ADMIN_TOKEN` value somewhere safe (1Password etc.) — it's needed for
`GET /api/licenses/:key`.

## 5. Deploy

```bash
fly deploy --app clipso-license-server
```

The `release_command` in `fly.toml` runs `npm run migrate` before the new
version takes traffic. `schema.sql` is idempotent, so this is safe on every
deploy.

Verify:

```bash
fly status --app clipso-license-server
curl https://clipso-license-server.fly.dev/health          # {"status":"ok",...}
curl https://clipso-license-server.fly.dev/health/ready     # {"database":"ok",...}
```

## 6. Custom domain: api.clipso.app

```bash
fly certs add api.clipso.app --app clipso-license-server
fly certs show api.clipso.app --app clipso-license-server   # shows the DNS target
```

Then at **Namecheap** (clipso.app → Advanced DNS), add:

| Type | Host | Value |
|---|---|---|
| CNAME | `api` | `clipso-license-server.fly.dev.` |

(or the A/AAAA values `fly certs show` prints, if you prefer). DNS propagates in
a few minutes; `fly certs show` flips to "Ready" once the cert is issued.

Verify:

```bash
curl https://api.clipso.app/health
```

## 7. Issue a license and test the app end-to-end

```bash
# from backend/, with DATABASE_URL pointing at prod (fly ssh console -C ... also works)
fly ssh console --app clipso-license-server -C "node generate-license.js you@example.com"
```

Open Clipso → Settings → License → enter the email + key → Activate. It should
flip to Pro. Confirm server-side:

```bash
curl -s https://api.clipso.app/api/licenses/<KEY> \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq
```

## 8. Paddle webhook (when going paid)

Paddle Dashboard → Developer Tools → Notifications → add destination:

- URL: `https://api.clipso.app/webhook/paddle`
- Events: `transaction.completed`, `transaction.updated`, `subscription.activated`,
  `subscription.canceled`, `subscription.past_due`
- Copy the signing secret → `fly secrets set PADDLE_WEBHOOK_SECRET=...`
- Use Paddle's "Send test event" and check `fly logs` for
  `Received Paddle webhook: transaction.completed`.

---

## Operations

| Task | Command |
|---|---|
| Logs | `fly logs --app clipso-license-server` |
| Shell | `fly ssh console --app clipso-license-server` |
| Re-run migration | `fly ssh console -C "npm run migrate"` |
| Rotate `ADMIN_TOKEN` | `fly secrets set ADMIN_TOKEN=$(openssl rand -hex 32)` |
| Scale | `fly scale count 2` / `fly scale vm shared-cpu-2x` |
| DB backup | `fly postgres backup list --app clipso-db` |

## Local development

```bash
cd backend
docker run -d --name clipso-db -e POSTGRES_PASSWORD=pw -e POSTGRES_DB=clipso_licenses -p 5432:5432 postgres:16
cp .env.example .env          # set DB_PASSWORD=pw
npm install
npm run migrate
npm run dev
RUN_DB_TESTS=1 DATABASE_URL=postgres://postgres:pw@localhost:5432/clipso_licenses DATABASE_SSL=disable npm test
```
