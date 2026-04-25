{ modulesPath, config, pkgs, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

  networking.hostName = "vm-control-01";
  networking.domain = "vi-metallum";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "ahci"
    "sd_mod"
    "sr_mod"
  ];

  networking.useDHCP = true;
  networking.useNetworkd = true;
  systemd.network.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMmlyQCPB0J0LYWpqfQFHcv80irO62bWzC1g5lyH5dY wumniam@gmail.com"
  ];

  # sops secrets
  sops.secrets.tailscale_authkey = {
    sopsFile = ../../secrets/vm-control-01/tailscale.yaml;
    key = "authkey";
  };

  sops.secrets.storage_box_password = {
    sopsFile = ../../secrets/vm-control-01/storage-box.yaml;
    key = "password";
    owner = "postgres";
    group = "postgres";
  };

  sops.secrets.telegram_bot_token = {
    sopsFile = ../../secrets/vm-control-01/telegram.yaml;
    key = "bot_token";
  };

  sops.secrets."n8n/env" = {
    sopsFile = ../../secrets/vm-control-01/n8n.yaml;
    key = "env";
  };

  sops.secrets."challenge/env" = {
    sopsFile = ../../secrets/vm-control-01/challenge.yaml;
    key = "env";
    owner = "challenge";
    group = "challenge";
    mode = "0400";
  };

  # n8n — installed via npm to /opt/n8n (nixpkgs build broken for 2.x)
  systemd.services.n8n = {
    description = "n8n workflow automation";
    after = [ "network-online.target" "postgresql.service" ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
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
        "N8N_EDITOR_BASE_URL=http://100.126.11.26:5678"
        "WEBHOOK_URL=http://100.126.11.26:5678"
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

  # Tailscale auto-connect on (re)deploy if not already running
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
        --authkey="$(cat ${config.sops.secrets.tailscale_authkey.path})"
    '';
  };

  system.stateVersion = "24.11";
}
