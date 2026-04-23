# vi-metallum-infra

Implementación de la arquitectura de Vi Metallum en NixOS + Terraform.

Las decisiones de arquitectura están en [`Willis75/arquitectura-legible`](https://github.com/Willis75/arquitectura-legible). Este repo las implementa; no las redefine.

## Estructura

```
flake.nix          — entrada del sistema NixOS declarativo
modules/           — módulos Nix reutilizables entre hosts
hosts/             — configuración específica por host
terraform/         — recursos Hetzner (VPS, networks, firewalls)
cloud-init/        — templates de inicialización por tipo de nodo
secrets/           — secretos cifrados con sops + age (ADR-004)
.sops.yaml         — reglas de cifrado
docs/adr/          — ADRs de implementación (los generales están en arquitectura-legible)
```

## Prerequisitos

- NixOS con flakes habilitado
- `age` y `sops` instalados
- `deploy-rs` (incluido en el flake)
- Clave age del operador generada y referenciada en `.sops.yaml`

## Uso

```bash
# Ver hosts disponibles
nix flake show

# Desplegar un host
deploy .#<hostname>

# Editar un secreto
sops secrets/<archivo>.yaml
```
