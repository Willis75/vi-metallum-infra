{ config, lib, ... }:

{
  systemd.services.paper-scheduler = {
    description = "Vi Metallum paper-scheduler";
    after = [ "network-online.target" "postgresql.service" "sops-nix.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "/opt/vi-metallum/bin/paper-scheduler -trader /opt/vi-metallum/scripts/paper_trader.py";
      EnvironmentFile = config.sops.secrets."postgres/database_url".path;
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
}
