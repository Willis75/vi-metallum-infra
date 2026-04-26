{ config, pkgs, ... }:

let
  agents = [
    { name = "voice-caller";   port = 3001; }
    { name = "telegram-bot";   port = 3002; }
    { name = "whatsapp-bot";   port = 3003; }
    { name = "image-generator"; port = 3004; }
    { name = "n8n-runner";     port = 3005; }
  ];

  mkAgentService = agent: {
    name = "challenge-${agent.name}";
    value = {
      description = "Challenge agent: ${agent.name}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = "/var/lib/challenge/agents/${agent.name}";
        ExecStart = "${pkgs.nodejs_22}/bin/node --env-file ${config.sops.secrets."challenge/env".path} dist/index.js";
        Restart = "on-failure";
        RestartSec = "5s";
        User = "challenge";
        Environment = "PORT=${toString agent.port}";
        MemoryMax = "500M";
      };
    };
  };
in
{
  users.users.challenge = {
    isSystemUser = true;
    group = "challenge";
    home = "/var/lib/challenge";
    createHome = true;
  };
  users.users.nginx.extraGroups = [ "challenge" ];
  users.groups.challenge = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/challenge            0750 challenge challenge -"
    "d /var/lib/challenge/data       0750 challenge challenge -"
    "d /var/lib/challenge/data/media 0755 challenge challenge -"
    "d /var/lib/challenge/agents     0750 challenge challenge -"
  ] ++ map (a: "d /var/lib/challenge/agents/${a.name}      0750 challenge challenge -") agents
    ++ map (a: "d /var/lib/challenge/agents/${a.name}/dist  0750 challenge challenge -") agents;

  systemd.services = builtins.listToAttrs (map mkAgentService agents);
}
