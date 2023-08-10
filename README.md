```
  nix build github:tpopp/nix-config#nixosConfigurations.deskmini-x300.config.system.build.toplevel
  ./result/activate
  sudo nixos-rebuild switch --flake .#deskmini-x300
```

```
  home-manager switch --flake github:tpopp/nix-config#tpopp
```
