{ modulesPath, config, pkgs, lib, ... }:

{
  imports = [
    ./disko.nix
  ];

  networking.hostName = "mtto-server";
  networking.domain = "vi-metallum";

  # Physical Intel NUC-class machine — override qemu from base.nix
  services.qemuGuest.enable = lib.mkForce false;

  # Local timezone (overrides Europe/Berlin from base.nix)
  time.timeZone = lib.mkForce "America/Monterrey";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  # DHCP on all interfaces — Ethernet preferred, WiFi as fallback
  networking.useDHCP = true;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Disable desktop/GUI services not needed on a headless server
  services.xserver.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMmlyQCPB0J0LYWpqfQFHcv80irO62bWzC1g5lyH5dY wumniam@gmail.com"
  ];

  # sops-nix: age key generated on first boot at this standard path
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Secrets — encrypted files created in F10.3 after age key generation
  sops.secrets."postgres/mtto_password" = {
    sopsFile = ../../secrets/mtto-server/postgres.yaml;
    key = "mtto_password";
    owner = "postgres";
  };
  sops.secrets."postgres/n8n_password" = {
    sopsFile = ../../secrets/mtto-server/postgres.yaml;
    key = "n8n_password";
    owner = "postgres";
  };
  # n8n/cloudflared secrets — re-enable when modules are activated via deploy-rs
  # sops.secrets."n8n/env" = { ... };
  # sops.secrets."cloudflared/token" = { ... };
  sops.secrets."tailscale/authkey" = {
    sopsFile = ../../secrets/mtto-server/tailscale.yaml;
    key = "authkey";
  };
  # mtto-albercas/minio secrets — re-enable via deploy-rs
  # sops.secrets."mtto-albercas/env" = { ... };
  sops.secrets."minio/credentials" = {
    sopsFile = ../../secrets/mtto-server/minio.yaml;
    key = "credentials";
    owner = "minio";
    mode = "0400";
  };

  # Tailscale auto-connect (same pattern as vm-control-01)
  systemd.services.tailscale-autoconnect = {
    description = "Tailscale auto-connect";
    after = [ "network-online.target" "tailscale.service" "sops-nix.service" ];
    wants = [ "network-online.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      state=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.BackendState // "error"' 2>/dev/null || echo error)
      if [ "$state" = "Running" ]; then exit 0; fi
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey="$(cat ${config.sops.secrets."tailscale/authkey".path})"
    '';
  };

  system.stateVersion = "25.05";
}
