#!/bin/bash
export PATH=/root/.nix-profile/bin:$PATH
cd "/mnt/c/Users/wumni/1 proyectos/vi-metallum-infra"

EXTRA=/tmp/nixos-anywhere-extra
mkdir -p "$EXTRA/var/lib/sops-nix"
cp /tmp/mtto-bootstrap.txt "$EXTRA/var/lib/sops-nix/key.txt"
chmod 400 "$EXTRA/var/lib/sops-nix/key.txt"

echo "=== Starting nixos-anywhere at $(date) ===" | tee /tmp/nixos-anywhere.log

nix run github:nix-community/nixos-anywhere -- \
  --flake ".#mtto-server" \
  --extra-files "$EXTRA" \
  --ssh-option "StrictHostKeyChecking=no" \
  wumni@100.95.51.67 2>&1 | tee -a /tmp/nixos-anywhere.log

echo "=== Exit: $? at $(date) ===" | tee -a /tmp/nixos-anywhere.log
