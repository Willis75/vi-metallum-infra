{ ... }:

# Reverse proxy for challenge agents — strips path prefix before proxying.
# Cloudflare Tunnel points agents.vimetallum.com → http://localhost:8080.
# nginx strips the leading segment and forwards to the correct agent port.
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."challenge-agents" = {
      listen = [{ addr = "127.0.0.1"; port = 8080; ssl = false; }];
      locations = {
        "/voice/"       = { proxyPass = "http://127.0.0.1:3001/"; };
        "/telegram/"    = { proxyPass = "http://127.0.0.1:3002/"; };
        "/whatsapp/"    = { proxyPass = "http://127.0.0.1:3003/"; };
        "/images/"      = { proxyPass = "http://127.0.0.1:3004/"; };
        "/n8n-trigger/" = { proxyPass = "http://127.0.0.1:3005/"; };
        "/media/" = {
          alias = "/var/lib/challenge/data/media/";
          extraConfig = ''
            add_header Access-Control-Allow-Origin *;
            expires 1h;
          '';
        };
        "= /health" = { proxyPass = "http://127.0.0.1:3001/health"; };
      };
    };
  };
}
