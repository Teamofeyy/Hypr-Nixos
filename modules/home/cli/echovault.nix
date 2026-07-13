{
  inputs,
  pkgs,
  ...
}:

let
  echovault = pkgs.callPackage ../../../pkgs/echovault.nix {
    src = inputs.echovault;
  };
in
{
  home.packages = [
    echovault
  ];
}