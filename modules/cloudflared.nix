{ config, pkgs, ... }:

{
  # Cloudflare Tunnel — outbound-only, exposes n8n.vimetallum.com to internet
  # without port forwarding. Token is a remote-managed tunnel token from the
  # Cloudflare Zero Trust dashboard (single string, not a JSON credentials file).
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel (n8n.vimetallum.com)";
    after    = [ "network-online.target" "n8n.service" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file ${config.sops.secrets."cloudflared/token".path}";
      Restart = "on-failure";
      RestartSec = "10s";
      User = "root";
    };
  };
}
