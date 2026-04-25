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
  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8821ce ];
  hardware.enableRedistributableFirmware = true;

  # DHCP on all interfaces — Ethernet preferred, WiFi as fallback
  networking.useDHCP = true;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # WiFi — bootstrap only, move to sops secret post-bootstrap
  networking.wireless.enable = true;
  networking.wireless.networks."INFINITUM19B0".psk = "mWHEe4C3Dx";

  # Disable desktop/GUI services not needed on a headless server
  services.xserver.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;

  # CUPS — print server fallback for HP LaserJet M451dn
  services.printing = {
    enable = lib.mkForce true;
    drivers = [ pkgs.hplip ];
    listenAddresses = [ "*:631" ];
    allowFrom = [
      "192.168.0.0/24"
      "192.168.1.0/24"
      "192.168.10.0/24"
      "192.168.195.0/24"
      "100.64.0.0/10"
    ];
    browsing = true;
    defaultShared = true;
  };

  hardware.printers.ensurePrinters = [{
    name = "hp-m451dn";
    location = "IOCSA";
    deviceUri = "socket://192.168.0.101:9100";
    model = "HP/hp-lj_300_400_color_m351_m451-ps.ppd.gz";
    ppdOptions.PageSize = "Letter";
  }];
  hardware.printers.ensureDefaultPrinter = "hp-m451dn";

  users.users.root.initialPassword = "nixos-bootstrap";
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
  sops.secrets."n8n/env" = {
    sopsFile = ../../secrets/mtto-server/n8n.yaml;
    key = "env";
  };
  sops.secrets."cloudflared/token" = {
    sopsFile = ../../secrets/mtto-server/cloudflared.yaml;
    key = "token";
  };
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

  # n8n — installed via npm to /opt/n8n (nixpkgs build broken for 2.x)
  systemd.services.n8n = {
    description = "n8n workflow automation";
    after = [ "network-online.target" "postgresql.service" ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.nodejs_22 ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/opt/n8n/bin/n8n start";
      Restart = "on-failure";
      RestartSec = "10s";
      User = "root";
      EnvironmentFile = config.sops.secrets."n8n/env".path;
      Environment = [
        "N8N_USER_FOLDER=/var/lib/n8n"
        "DB_TYPE=postgresdb"
        "DB_POSTGRESDB_HOST=localhost"
        "DB_POSTGRESDB_PORT=5432"
        "DB_POSTGRESDB_DATABASE=n8n"
        "DB_POSTGRESDB_USER=n8n"
        "N8N_HOST=0.0.0.0"
        "N8N_PORT=5678"
        "N8N_EDITOR_BASE_URL=https://n8n.vimetallum.com"
        "WEBHOOK_URL=https://n8n.vimetallum.com"
        "N8N_SECURE_COOKIE=false"
        "EXECUTIONS_MODE=regular"
        "GENERIC_TIMEZONE=America/Monterrey"
        "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/n8n 0750 root root -"
  ];

  # Tailscale auto-connect (same pattern as vm-control-01)
  systemd.services.tailscale-autoconnect = {
    description = "Tailscale auto-connect";
    after = [ "network-online.target" "tailscale.service" ];
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
