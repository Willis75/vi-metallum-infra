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
- Hosts vacíos — completar cuando se decidan los nombres y servicios por host.

## Estado actual

**Scaffold inicial — sin hosts definidos aún.** Las decisiones de migración/provisión están pendientes.

## Relación con otros repos

- `Willis75/arquitectura-legible` — fuente autoritativa de ADRs y doctrina.
- Este repo referencia esos ADRs; no los duplica ni los contradice.
