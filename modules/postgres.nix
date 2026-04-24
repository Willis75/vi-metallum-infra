{ config, pkgs, lib, ... }:

let
  storageBoxKnownHosts = pkgs.writeText "storagebox-known-hosts" ''
    u583114.your-storagebox.de ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==
  '';
in
{
  # Two-stage WAL archive:
  # Stage 1 — postgres cp to local staging dir (no network, no seccomp issues)
  # Stage 2 — rclone timer syncs staging → Storage Box every 5 min

  systemd.tmpfiles.rules = [
    "d /var/lib/wal-archive 0750 postgres postgres -"
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;

    settings = {
      listen_addresses = "*";
      wal_level = "replica";
      archive_mode = "on";
      archive_command = "cp %p /var/lib/wal-archive/%f";
      archive_timeout = 300;
      max_wal_senders = 3;
    };

    authentication = lib.mkOverride 10 ''
      local all all trust
      local replication all trust
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
      host all all 100.64.0.0/10 scram-sha-256
      host replication all 127.0.0.1/32 scram-sha-256
      host replication all 100.64.0.0/10 scram-sha-256
    '';

    ensureDatabases = [ "vi_metallum" ];
    ensureUsers = [
      { name = "vimet_admin"; ensureDBOwnership = false; }
    ];
  };

  # Allow postgres service to write to staging dir
  systemd.services.postgresql.serviceConfig.ReadWritePaths =
    lib.mkAfter [ "/var/lib/wal-archive" ];

  # Stage 2: rclone timer — sync staging dir to Storage Box
  systemd.services.wal-archive-push = {
    description = "Push staged WAL segments to Storage Box";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      PASS=$(cat ${config.sops.secrets.storage_box_password.path})
      OBSCURED=$(${pkgs.rclone}/bin/rclone obscure "$PASS")
      ${pkgs.rclone}/bin/rclone sync \
        --sftp-host u583114.your-storagebox.de \
        --sftp-user u583114 \
        --sftp-pass "$OBSCURED" \
        --sftp-known-hosts-file ${storageBoxKnownHosts} \
        /var/lib/wal-archive ":sftp:/wal-archive/vm-control-01/"
    '';
  };

  systemd.timers.wal-archive-push = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      RandomizedDelaySec = "30s";
      Persistent = true;
    };
  };
}
