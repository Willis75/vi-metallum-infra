{ config, pkgs, lib, ... }:

{
  services.n8n = {
    enable = true;
    settings = {
      # Non-secret settings — credentials come via EnvironmentFile
      db.type = "postgresdb";
      db.postgresdb.host = "localhost";
      db.postgresdb.port = 5432;
      db.postgresdb.database = "n8n";
      db.postgresdb.user = "n8n";

      queue.bull.redis.host = "localhost";
      queue.bull.redis.port = 6379;

      executions.mode = "regular";

      generic.timezone = "America/Monterrey";

      "n8n.editor_base_url" = "https://n8n.vimetallum.com";
      "n8n.webhook_url" = "https://n8n.vimetallum.com";
      "n8n.secure_cookie" = true;
      "n8n.proxy_hops" = 1;

      "n8n.community_packages_allow_tool_usage" = true;
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
