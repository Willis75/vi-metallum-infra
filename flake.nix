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

    blue5pl-tbl = {
      url = "github:Willis75/Blue5PL-TBL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, sops-nix, deploy-rs, blue5pl-tbl, ... }:
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
            ./modules/redis.nix
            # ./modules/n8n.nix  # n8n installed via npm post-deploy (nixpkgs build fails)
            ./modules/challenge.nix
            ./modules/cloudflared.nix
            ./modules/nginx-agents.nix
            ./modules/paper-scheduler.nix
            ./modules/python-ml.nix
            blue5pl-tbl.nixosModules.tbl
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
            # ./modules/n8n.nix          # nixpkgs build broken; n8n installed via npm, service in host config
            ./modules/cloudflared.nix
            ./modules/minio.nix
            # ./modules/caddy-local.nix  # re-enable via deploy-rs after bootstrap
            # ./modules/mtto-albercas.nix # re-enable via deploy-rs after bootstrap
            # ./modules/stock-radar.nix  # re-enable via deploy-rs after bootstrap
            ./hosts/mtto-server
          ];
        };
      };

      deploy.nodes.vm-control-01 = {
        hostname = "100.126.11.26"; # Tailscale IP (public IP 178.104.209.199 blocks SSH)
        profiles.system = {
          user = "root";
          sshUser = "root";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.vm-control-01;
        };
      };

      deploy.nodes.mtto-server = {
        # Deploy via Tailscale IP
        hostname = "100.72.143.71";
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
