{ config, pkgs, lib, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;

    settings = {
      # Accept connections from localhost and Tailscale CIDR
      listen_addresses = lib.mkForce "localhost";
      port = 5432;
    };

    authentication = lib.mkOverride 10 ''
      local all all              peer
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128       scram-sha-256
      host  all all 100.64.0.0/10 scram-sha-256
    '';

    ensureDatabases = [ "mtto_albercas" "n8n" ];
    ensureUsers = [
      { name = "mtto"; ensureDBOwnership = false; }
      { name = "n8n";  ensureDBOwnership = false; }
    ];
  };

  # Grant DB ownership and set passwords from sops secrets.
  # Type=oneshot + RemainAfterExit makes it run once per boot idempotently.
  systemd.services.postgres-setup = {
    description = "Grant DB ownership and set service user passwords";
    after    = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      psql -c "GRANT ALL ON DATABASE mtto_albercas TO mtto;"
      psql -c "GRANT ALL ON DATABASE n8n TO n8n;"
      MTTO=$(cat ${config.sops.secrets."postgres/mtto_password".path})
      N8N=$(cat ${config.sops.secrets."postgres/n8n_password".path})
      psql -c "ALTER USER mtto PASSWORD '$MTTO';"
      psql -c "ALTER USER n8n  PASSWORD '$N8N';"
    '';
  };
}
