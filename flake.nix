{
  description = "Vi Metallum infrastructure — NixOS hosts, secrets, deploy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, sops-nix, deploy-rs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      nixosConfigurations = {
        vm-control-01 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules/secrets.nix
            ./modules/base.nix
            ./modules/hardening.nix
            ./modules/postgres.nix
            ./modules/paper-scheduler.nix
            ./modules/python-ml.nix
            ./hosts/vm-control-01
          ];
        };

        mtto-server = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules/base.nix
            ./modules/hardening.nix
            ./modules/postgres-local.nix
            ./modules/redis.nix
            ./modules/n8n.nix
            ./modules/cloudflared.nix
            ./modules/minio.nix
            ./modules/caddy-local.nix
            ./modules/mtto-albercas.nix
            ./modules/stock-radar.nix
            ./hosts/mtto-server
          ];
        };
      };

      deploy.nodes.vm-control-01 = {
        hostname = "178.104.209.199";
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.vm-control-01;
        };
      };

      deploy.nodes.mtto-server = {
        # Deploy via Tailscale IP
        hostname = "100.95.51.67";
        profiles.system = {
          user = "root";
          sshUser = "wumni";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.mtto-server;
        };
      };

      checks = builtins.mapAttrs
        (_: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nix
          age
          sops
          deploy-rs.packages.${system}.default
        ];
      };
    };
}
