# ADR — mtto-server

**Host:** HP ProDesk G2 Mini (local, red IOCSA 192.168.195.60 / WiFi 192.168.1.88)  
**Tailscale IP:** 100.95.51.67  
**Convertido a NixOS:** 2026-04-xx (kexec desde Ubuntu 24.04)

## Propósito

Host de servicios locales consolidados bajo doctrina Vi Metallum:

| Servicio | Puerto | Acceso |
|----------|--------|--------|
| n8n | 5678 | Cloudflare Tunnel → n8n.vimetallum.com |
| mtto-albercas API | 8000 | LAN/Tailscale (Caddy en :80) |
| MinIO | 9000/9001 | Tailscale solo |
| stock-radar | 5050 | Tailscale solo |
| Postgres 16 | 5432 | localhost + Tailscale |
| Redis | 6379 | localhost solo |

## Por qué esta máquina

- Recursos suficientes: 7.6GB RAM, 233GB NVMe
- Ya era host productivo de mtto-albercas
- Física local → sin costo de VPS
- Absorbe blue5pl (Hetzner VM €6/mes) + n8n de paperless

## Secretos

Todos encriptados con age key del host en `/var/lib/sops-nix/key.txt`.  
Archivos en `secrets/mtto-server/`:

- `postgres.yaml` — passwords de usuarios mtto y n8n
- `n8n.yaml` — EnvironmentFile: DB_POSTGRESDB_PASSWORD, N8N_ENCRYPTION_KEY, N8N_API_KEY
- `cloudflared.yaml` — token del tunnel (Cloudflare Zero Trust dashboard)
- `tailscale.yaml` — authkey reusable de la tailnet vi-metallum
- `mtto-albercas.yaml` — EnvironmentFile: DATABASE_URL, JWT_SECRET, PORT, MIGRATIONS_DIR
- `minio.yaml` — MINIO_ROOT_USER + MINIO_ROOT_PASSWORD

## Procedimiento de bootstrap (F10.3)

1. `nixos-anywhere --flake .#mtto-server --kexec-url ... wumni@100.95.51.67`
2. SSH al host tras reboot: generar age key con `age-keygen -o /var/lib/sops-nix/key.txt`
3. Agregar pubkey al `.sops.yaml` del repo
4. Crear y encriptar `secrets/mtto-server/*.yaml` con `sops encrypt`
5. `deploy .#mtto-server` — full deploy con secretos
6. Restaurar datos: `pg_restore`, `mc mirror` para MinIO, copiar binario mtto-albercas
