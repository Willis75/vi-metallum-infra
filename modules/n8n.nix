{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "n8n" ];

  services.n8n = {
    enable = true;
    environment = {
      DB_TYPE                               = "postgresdb";
      DB_POSTGRESDB_HOST                    = "localhost";
      DB_POSTGRESDB_PORT                    = "5432";
      DB_POSTGRESDB_DATABASE                = "n8n";
      DB_POSTGRESDB_USER                    = "n8n";
      N8N_HOST                              = lib.mkDefault "0.0.0.0";
      EXECUTIONS_MODE                       = "regular";
      GENERIC_TIMEZONE                      = "America/Monterrey";
      N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true";
    };
  };

  services.postgresql.ensureDatabases = [ "n8n" ];
  services.postgresql.ensureUsers = [
    { name = "n8n"; ensureDBOwnership = false; }
  ];

  systemd.services.n8n = {
    after    = lib.mkAfter [ "postgresql.service" ];
    requires = lib.mkAfter [ "postgresql.service" ];
    serviceConfig.EnvironmentFile = lib.mkAfter [
      config.sops.secrets."n8n/env".path
    ];
  };
}
