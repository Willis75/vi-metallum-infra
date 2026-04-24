{ ... }:

{
  services.caddy = {
    enable = true;
    # mtto-albercas frontend served on LAN port 80.
    # n8n is NOT served here — it's exposed only via Cloudflare Tunnel on 5678.
    virtualHosts."http://:80" = {
      extraConfig = ''
        root * /var/lib/mtto-albercas/frontend
        file_server

        handle /api/* {
          reverse_proxy localhost:8000
        }

        handle /health {
          reverse_proxy localhost:8000
        }
      '';
    };
  };

  # Open port 80 on LAN interface only (Tailscale interface is already trusted)
  networking.firewall.allowedTCPPorts = [ 80 ];
}
