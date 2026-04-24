{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    numpy
    stable-baselines3
    gymnasium
  ]);
in
{
  environment.systemPackages = [ pythonEnv ];
}
