{ config, pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    flask
    requests
    pandas
  ]);
in
{
  users.users.stock-radar = {
    isSystemUser = true;
    group = "stock-radar";
    home = "/var/lib/stock-radar";
    createHome = true;
  };
  users.groups.stock-radar = {};

  systemd.services.stock-radar = {
    description = "Stock Radar Dashboard";
    after    = [ "network-online.target" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "stock-radar";
      WorkingDirectory = "/var/lib/stock-radar";
      ExecStart = "${pythonEnv}/bin/python3 /var/lib/stock-radar/app.py";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
