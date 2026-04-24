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
