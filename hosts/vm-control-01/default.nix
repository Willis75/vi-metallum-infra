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
    restartUnits = [ "n8n.service" ];
  };

  sops.secrets."n8n/db_password" = {
    sopsFile = ../../secrets/vm-control-01/n8n.yaml;
    key = "db_password";
    owner = "postgres";
    group = "postgres";
  };

  sops.secrets."challenge/env" = {
    sopsFile = ../../secrets/vm-control-01/challenge.yaml;
    key = "env";
    owner = "challenge";
    group = "challenge";
    mode = "0400";
  };

  # n8n: grant DB, set password on first boot
  systemd.services.n8n-db-setup = {
    description = "n8n DB ownership and password setup";
    after    = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    path = [ pkgs.postgresql_16 ];
    script = ''
      psql -c "GRANT ALL ON DATABASE n8n TO n8n;"
      PASS=$(cat ${config.sops.secrets."n8n/db_password".path})
      psql -c "ALTER USER n8n PASSWORD '$PASS';"
    '';
  };

  services.n8n.environment = {
    N8N_EDITOR_BASE_URL = "http://100.126.11.26:5678";
    WEBHOOK_URL         = "http://100.126.11.26:5678";
    N8N_SECURE_COOKIE   = "false";
  };

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
