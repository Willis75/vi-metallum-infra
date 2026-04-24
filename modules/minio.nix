{ config, pkgs, lib, ... }:

{
  services.minio = {
    enable = true;
    dataDir = [ "/var/lib/minio/data" ];
    configDir = "/var/lib/minio/config";
    listenAddress = "127.0.0.1:9000";
    consoleAddress = "127.0.0.1:9001";
    rootCredentialsFile = config.sops.secrets."minio/credentials".path;
  };

  # MinIO data dir
  systemd.tmpfiles.rules = [
    "d /var/lib/minio/data   0750 minio minio -"
    "d /var/lib/minio/config 0750 minio minio -"
  ];

  systemd.services.minio = {
    after    = lib.mkAfter [ "sops-nix.service" ];
    requires = lib.mkAfter [ "sops-nix.service" ];
  };
}
