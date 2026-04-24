{ config, pkgs, ... }:

{
  users.users.mtto-albercas = {
    isSystemUser = true;
    group = "mtto-albercas";
    home = "/var/lib/mtto-albercas";
    createHome = true;
  };
  users.groups.mtto-albercas = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/mtto-albercas           0750 mtto-albercas mtto-albercas -"
    "d /var/lib/mtto-albercas/migrations 0750 mtto-albercas mtto-albercas -"
    "d /var/lib/mtto-albercas/frontend   0755 mtto-albercas mtto-albercas -"
  ];

  systemd.services.mtto-albercas = {
    description = "mtto-albercas API";
    after    = [ "network-online.target" "postgresql.service" "sops-nix.service" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "mtto-albercas";
      WorkingDirectory = "/var/lib/mtto-albercas";
      # Binary deployed manually to this path after restore (not nix-managed)
      ExecStart = "/var/lib/mtto-albercas/bin/api";
      EnvironmentFile = config.sops.secrets."mtto-albercas/env".path;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
