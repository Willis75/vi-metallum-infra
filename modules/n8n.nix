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
      QUEUE_BULL_REDIS_HOST                 = "localhost";
      QUEUE_BULL_REDIS_PORT                 = "6379";
      EXECUTIONS_MODE                       = "regular";
      GENERIC_TIMEZONE                      = "America/Monterrey";
      N8N_EDITOR_BASE_URL                   = "https://n8n.vimetallum.com";
      WEBHOOK_URL                           = "https://n8n.vimetallum.com";
      N8N_SECURE_COOKIE                     = "true";
      N8N_PROXY_HOPS                        = "1";
      N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true";
    };
  };

  # Inject secrets (DB password, encryption key, API key) at runtime
  systemd.services.n8n = {
    after    = lib.mkAfter [ "sops-nix.service" "postgresql.service" "redis-main.service" ];
    requires = lib.mkAfter [ "sops-nix.service" "postgresql.service" ];
    serviceConfig.EnvironmentFile = lib.mkAfter [
      config.sops.secrets."n8n/env".path
    ];
  };
}
