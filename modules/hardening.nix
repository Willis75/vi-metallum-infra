{
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;
      PermitEmptyPasswords = "no";
      MaxAuthTries = 3;
      LoginGraceTime = 20;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    trustedInterfaces = [ "tailscale0" ];
    # Cloudflare proxy IPs — allow :5678 only from CF edge (n8nch.vimetallum.com)
    extraInputRules = ''
      ip saddr {
        103.21.244.0/22, 103.22.200.0/22, 103.31.4.0/22,
        104.16.0.0/13, 104.24.0.0/14,
        108.162.192.0/18, 131.0.72.0/22,
        141.101.64.0/18, 162.158.0.0/15,
        172.64.0.0/13, 173.245.48.0/20,
        188.114.96.0/20, 190.93.240.0/20,
        197.234.240.0/22, 198.41.128.0/17
      } tcp dport 5678 accept
    '';
    logRefusedConnections = false;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
      overalljails = true;
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
  };
}
