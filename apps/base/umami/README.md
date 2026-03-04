# Umami Analytics

Privacy-focused, cookie-free web analytics for StreamSquire. Self-hosted alternative to Google Analytics — no tracking cookies, no fingerprinting, no personal data stored. GDPR-compliant without a consent banner.

**Stack:** Umami v3 + PostgreSQL 16 (sidecar)

## How It Works

1. `streamsquire.app` loads a ~2KB script from `analytics.streamsquire.app/script.js`
2. On each page view, the script sends a POST to `analytics.streamsquire.app/api/send` with: page URL, referrer, browser, OS, screen size, language
3. Umami aggregates the data into PostgreSQL — no cookies, no IPs stored, no user-level tracking
4. View the dashboard at `https://analytics.streamsquire.app` (login required)

## Website Integration

The tracking script is in `website/index.html`:

```html
<script defer src="https://analytics.streamsquire.app/script.js" data-website-id="<UUID>"></script>
```

The `data-website-id` UUID is generated in the Umami dashboard after adding the website (Settings → Websites → Add).

### Custom Event Tracking

Track button clicks with `data-umami-event` attributes (no JS needed):

```html
<a href="/download" data-umami-event="download-click">Download</a>
<button data-umami-event="pricing-subscribe" data-umami-event-tier="knight">Subscribe</button>
```

## DNS

Add a CNAME or A record in Cloudflare:

```
analytics.streamsquire.app → cluster IP (same as streamsquire.app)
```

## Kubernetes Resources

- **Namespace**: `umami`
- **Deployment**: single pod with two containers:
  - `umami` — Umami v3 app on port 3000
  - `postgres` — PostgreSQL 16 sidecar on port 5432 (localhost)
- **Service**: port 80 → 3000
- **PVC** (overlay): 1Gi NFS for Postgres data persistence
- **Ingress** (overlay): `analytics.streamsquire.app` via Traefik with TLS
- **Certificate**: auto-issued by cert-manager via Cloudflare DNS-01

## Post-Deploy Setup

```sh
# 1. Check pod is running
kubectl get pods -n umami

# 2. Check logs
kubectl logs -n umami -l app=umami -c umami
kubectl logs -n umami -l app=umami -c postgres

# 3. Visit https://analytics.streamsquire.app
# Default login: admin / umami
# CHANGE THE PASSWORD IMMEDIATELY

# 4. Add website in dashboard:
#    Settings → Websites → Add website
#    Name: StreamSquire
#    Domain: streamsquire.app

# 5. Copy the Website ID (UUID) and update website/index.html:
#    data-website-id="<paste UUID here>"

# 6. Rebuild and redeploy the website
```

## What It Tracks

| Metric | Description |
|---|---|
| Page views | Which pages are visited, how often |
| Visitors | Unique visitors (session-based, no cookies) |
| Referrers | Where traffic comes from |
| Browsers | Chrome, Firefox, Safari, etc. |
| OS | Windows, macOS, Linux, iOS, Android |
| Countries | Visitor geography (from request, not stored) |
| Screen sizes | Desktop vs mobile vs tablet |
| Custom events | Download clicks, pricing interactions, etc. |

## What It Does NOT Track

- No cookies set
- No IP addresses stored
- No fingerprinting
- No cross-site tracking
- No personal data collected
- Fully GDPR/ePrivacy compliant without consent banner
