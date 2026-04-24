{ config, ... }:

{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets."postgres/database_url" = {
    sopsFile = ../secrets/vm-control-01/postgres.yaml;
    key      = "database_url";
    owner    = "root";
    mode     = "0400";
  };
}
