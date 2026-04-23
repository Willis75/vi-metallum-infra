{
  description = "Vi Metallum infrastructure — NixOS hosts, Terraform, secrets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, deploy-rs, sops-nix }: {
    nixosConfigurations = {
    };

    deploy.nodes = {
    };
  };
}
