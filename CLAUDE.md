# CLAUDE.md — vi-metallum-infra

## Qué es este repo

Implementación de la arquitectura de Vi Metallum: NixOS hosts, Terraform (Hetzner), secrets con sops+age, deploy con deploy-rs.

**Las decisiones de arquitectura son autoritativas en [`Willis75/arquitectura-legible`](https://github.com/Willis75/arquitectura-legible).** Este repo implementa esas decisiones. Cualquier conflicto entre este CLAUDE.md y los ADRs de `arquitectura-legible` se resuelve a favor de los ADRs.

## Reglas de oro

1. Ningún secreto en texto plano en git — todo pasa por sops+age (ADR-004).
2. Ningún cambio a un host sin pasar el Pre-Deploy Gate del protocolo de desarrollo.
3. `flake.nix` es la fuente de verdad. Lo que no está en el flake no es parte del sistema.
4. Los módulos en `modules/` son reutilizables entre hosts. La configuración específica va en `hosts/<hostname>/`.
5. El estado de Terraform se define cuando se elija el backend. Hasta entonces: no usar `terraform apply` sin backend remoto configurado.

## Estructura de hosts

Cuando se agregue un host, seguir la estructura:

```
hosts/
  <hostname>/
    default.nix    — configuración del host (importa módulos)
    hardware.nix   — configuración de hardware (generada por nixos-generate-config)
```

## Pre-Deploy Gate obligatorio

Antes de cualquier `deploy-rs`, `terraform apply`, o `nixos-rebuild switch` en producción:

1. ¿El cambio está en el flake (fuente de verdad), no solo aplicado imperativamente?
2. ¿Los contratos entre módulos se verificaron (nombres de opciones, interfaces)?
3. ¿Hay plan de rollback? (deploy-rs tiene magic rollback — verificar que está activo)
4. Declarar qué se despliega dónde. Esperar confirmación del operador.

## Deuda inicial documentada

- `.sops.yaml` tiene placeholder en lugar de clave age real — completar al generar la primera clave age del operador.
- `terraform/` vacío — completar cuando se defina el backend de state y el primer VPS.

## Estado actual (2026-04-27)

vm-control-01 activo con: Postgres 16, Valkey, n8n (npm), challenge agents, Cloudflare Tunnel, Tailscale.

**Sprint 1 TBL:** `blue5pl-tbl` añadido como flake input; `nixosModules.tbl` importado en vm-control-01. 

### Pre-deploy TBL (antes del primer `deploy .#vm-control-01` con TBL):

1. Crear secret cifrado en vm-control-01 (requiere clave age privada):
   ```bash
   # En máquina con age private key:
   sops secrets/vm-control-01/tbl.yaml
   # Contenido plaintext:
   # env: |
   #   TBL_MODE=real
   #   DATABASE_URL=postgres://tbl@localhost/tbl
   #   VALKEY_ADDR=localhost:6379
   #   SAMSARA_TOKEN=<token-del-cliente>
   #   SAMSARA_WEBHOOK_SECRET=<secret-del-cliente>
   #   TWILIO_ACCOUNT_SID=<sid>
   #   TWILIO_AUTH_TOKEN=<token>
   #   TWILIO_FROM_NUMBER=whatsapp:+14155238886
   #   TWILIO_VOICE_NUMBER=+1xxxxxxxxxx
   #   ELEVENLABS_API_KEY=<key>
   #   ELEVENLABS_VOICE_ID=<voice-id>
   #   GCP_SERVICE_ACCOUNT_JSON=<base64-sa-json>
   #   BILLING_MANAGER_EMAIL=<email-tbl>
   ```
2. Añadir ruta en Cloudflare Zero Trust dashboard:
   - Tunnel → Public Hostname → Add
   - Subdomain: `tbl`, Domain: `vimetallum.com`
   - Service: `http://localhost:8081`
3. Verificar: `nix flake update blue5pl-tbl` y `nix build .#nixosConfigurations.vm-control-01.config.system.build.toplevel`
4. Declarar y esperar confirmación del operador antes de `deploy .#vm-control-01`

## Relación con otros repos

- `Willis75/arquitectura-legible` — fuente autoritativa de ADRs y doctrina.
- Este repo referencia esos ADRs; no los duplica ni los contradice.
