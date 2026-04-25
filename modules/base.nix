{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = false;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    tmux
    rsync
    rclone
    age
    sops
    jq
    tcpdump
    file
    nodejs_22
  ];

  services.qemuGuest.enable = true;

  services.tailscale.enable = true;

  documentation.nixos.enable = false;
}
