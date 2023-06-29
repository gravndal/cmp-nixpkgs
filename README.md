# cmp-nixpkgs

Consider using https://github.com/oxalica/nil or https://github.com/nix-community/nixd instead.

Contains two sources:
* `nixpkgs` for `pkgs`, `lib`, and `config`.
* `nixos` for NixOS modules.

The sources assume that there are two flakes named `self` and `nixpkgs` in the flake registry, and that these flakes in turn both output `legacyPackages`.

It's recommended to pin `nixpkgs` in your flake registry to avoid potentially slow lookups of suggestions for `prev` and `super`.
See [this post](https://discourse.nixos.org/t/my-painpoints-with-flakes/9750/14) on the discourse for a way to do so.

By default, completion for `final/prev` and `self/super` is only enabled in buffers whose full filename starts with `resolve('/etc/nixos') .. '/overlay'`.
This is configurable through `g:cmp_nixpkgs_overlay`.[^overlay]

NixOS module completion is only enabled for files under `resolve('/etc/nixos/')`.
The suggestions are attribute paths found under `config`[^1], as a consequence, these suggestions will match your currently running system so long as `self` is properly pinned.[^howisthisdifferentfromnixpkgsconfig]

If `manix` is in `PATH`, then it will be used to resolve documentation for `lib` and NixOS modules.

Depends on https://github.com/nvim-treesitter/nvim-treesitter.

[^1]: More accurately `self#nixosConfigurations.$hostname.config`.
[^overlay]: To take effect, this must be set before the `nixpkgs` source is initialised.
[^howisthisdifferentfromnixpkgsconfig]: There is some overlap between the `nixos` source and the `config` completion from `nixpkgs`, however there is a significant difference in that the two sources don't use the same tree-sitter context.
