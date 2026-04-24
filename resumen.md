# Resumen de Sesión — vi-metallum-infra — 2026-04-24

## Completado

### Fase A (sesión anterior)
- Flake NixOS: `flake.nix`, `hosts/vm-control-01/{default.nix,disko.nix}`, `modules/{base.nix,hardening.nix}`
- `nix flake check` ✅ — `nixos-anywhere` ejecutado — NixOS 26.05 instalado (kernel 6.18.23)

### Fase B
- SSH al host `178.104.209.199` — host confirmado
- `tailscale up` → `vm-control-01` en `100.126.11.26`
- `age-keygen -o /var/lib/sops-nix/key.txt` — pubkey: `age1gl7leqyhfvyaflc7t5cktjq4k75qwnd4kyk79td03lkpxxr35fps03lpuf`

### Fase C
- `.sops.yaml` actualizado con age pubkey real del host
- Secretos encriptados (AES256-GCM): `tailscale.yaml`, `storage-box.yaml`, `telegram.yaml`
- Commit `b93398b`

### Fase D
- `modules/secrets.nix`: sops age key path
- `modules/postgres.nix`: Postgres 16 + two-stage WAL archive
  - Stage 1: `archive_command = "cp %p /var/lib/wal-archive/%f"` (local, sin seccomp issues)
  - Stage 2: `wal-archive-push.timer` cada 5min → Storage Box via rclone SFTP
- `hosts/vm-control-01/default.nix`: sops secrets + `tailscale-autoconnect.service`
- `flake.nix`: sops-nix module + postgres + secrets modules
- Commit `76d9d30`

### PITR Test ✅ GATE VERDE
- Recovery target `18:05:38` → `recovery stopping before commit at 18:05:42 (T2)`
- T1 row presente, T2 ausente — PITR verificado
- Secuencia: base backup → insert T1 → insert T2 → restore → recovery a T1

## Pendientes
- Fase 2: scaffolding Go — `rl-crypto-trading-v2/` con módulos, ADRs, migrations
- Freeze del sistema legacy (`rl-crypto-trading/FREEZE.md` + postmortem)
- Ajuste firewall: cerrar SSH público (puerto 22) a Tailscale-only después de confirmar acceso Tailscale estable
- `vimet_admin` role en Postgres necesita `GRANT SUPERUSER` manual (o via NixOS `ensureClauses` cuando se configure)

## Riesgos / Watch Items
- `wal-archive-push.service` corre como root — revisar si puede correr como usuario dedicado
- WAL staging en `/var/lib/wal-archive/` — mismo disco que data dir; si el disco se llena, ambos fallan
- `deploy-rs` requiere `nix develop --command deploy` (no está en PATH global de WSL)
- CGNAT: acceso SSH público todavía habilitado en Hetzner firewall — mover a Tailscale-only en Fase 2

## Decisiones tomadas
- Two-stage WAL archive (cp local + rclone timer) — evita seccomp/SIGSYS de Postgres `SystemCallFilter=~@resources`
- Data dir NixOS Postgres 16: `/var/lib/postgresql/16/` (no `/16/main/`)
- PITR restore: `recovery.signal` + `postgresql.auto.conf` en data dir — sobrevive pre-start NixOS (solo symlinks `postgresql.conf`)
- `wal-archive-push` usa known_hosts pinned en nix store (no TOFU, no skip verification)

## Archivos modificados
- `flake.nix` — añadidos sops-nix + postgres + secrets modules
- `modules/secrets.nix` — creado
- `modules/postgres.nix` — creado (two-stage WAL archive)
- `hosts/vm-control-01/default.nix` — sops secrets + tailscale-autoconnect
- `.sops.yaml` — age pubkey real
- `secrets/vm-control-01/{tailscale,storage-box,telegram}.yaml` — encriptados
