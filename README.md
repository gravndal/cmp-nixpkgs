# cmp-nixpkgs
Contains two sources:
* `nixpkgs` for `pkgs` and `lib`.
* `nixos` for NixOS modules.

The sources assume that there are two flakes named `self` and `nixpkgs` in the flake registry, and that these flakes in turn both output `legacyPackages`.

It's recommended to pin `nixpkgs` in your flake registry to avoid potentially slow lookups of suggestions for `prev` and `super`.
See [this post](https://discourse.nixos.org/t/my-painpoints-with-flakes/9750/14) on the discourse for a way to do so.

NixOS module completion is only enabled for files under `resolve('/etc/nixos/')`.
The suggestions are attribute paths found under `config`[^1], as a consequence, these suggestions will match your currently running system so long as `self` is properly pinned.

If `manix` is in `PATH`, then it will be used to resolve documentation for `lib` and NixOS modules.

Depends on https://github.com/nvim-treesitter/nvim-treesitter.

[^1]: More accurately `self#nixosConfigurations.$hostname.config`.
