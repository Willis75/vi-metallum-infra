# Resumen de Sesión — vi-metallum-infra — 2026-04-24

## Completado
- Flake NixOS escrito: `flake.nix`, `hosts/vm-control-01/{default.nix,disko.nix}`, `modules/{base.nix,hardening.nix}`
- `flake.lock` generado (nixpkgs b12141e, disko 32f4236, sops-nix bef289e, deploy-rs 77c906c)
- `nix flake check` pasó limpio (✅ deploy-activate ✅ deploy-schema)
- `nixos-anywhere` ejecutado exitosamente — Ubuntu borrado, NixOS 26.05 instalado en vm-control-01
- Host arrancando: kernel 6.18.23, systemd-boot UEFI, ext4 GPT, SSH root con key ed25519

## Pendientes
- Fase B: SSH al host → `tailscale up` manual + `age-keygen -o /var/lib/sops-nix/key.txt`
- Fase C: agregar age pubkey al `.sops.yaml`, encriptar secretos (Tailscale authkey, Telegram token, Storage Box password), rebuild con deploy-rs
- Fase D: escribir `modules/postgres.nix` (Postgres 16, bind Tailscale, WAL archive a Storage Box BX11)
- Test PITR (gate obligatorio antes de Fase 2 / código Go)
- Commit del flake.lock + archivos staged a `vi-metallum-infra`

## Riesgos / Watch Items
- SSH key del laptop (WSL permisos 0777 en `/mnt/c/...`) — usar `/root/.ssh/id_ed25519` en WSL
- CGNAT multi-WAN: firewall Hetzner permite 189.159.84.187/32 + 187.190.176.212/32; moverse a Tailscale-only después de Fase B
- `.sops.yaml` tiene placeholder de age key — no encriptar secretos reales hasta generar la key en el host
- nixos-anywhere necesita `--ssh-option "IdentityFile=/root/.ssh/id_ed25519"` y `--kexec none` si el host ya está en kexec

## Decisiones tomadas
- cpx32 FSN1 (4vCPU/8GB/160GB AMD) — Storage Box BX11 1TB para WAL
- UEFI + systemd-boot + GPT (ESP 512M vfat + root 100% ext4 noatime)
- Bootstrap sin sops-nix primero (Fase A) → age key post-install (Fase B) → sops secretos (Fase C)
- Workers GPU (blue5pl, mtto-server) quedan en Ubuntu; NixOS-ificar en Fase 10+

## Archivos modificados
- `vi-metallum-infra/flake.nix` — reescrito con inputs reales + deploy node
- `vi-metallum-infra/flake.lock` — generado nuevo
- `vi-metallum-infra/hosts/vm-control-01/default.nix` — creado
- `vi-metallum-infra/hosts/vm-control-01/disko.nix` — creado
- `vi-metallum-infra/modules/base.nix` — creado
- `vi-metallum-infra/modules/hardening.nix` — creado
