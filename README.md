# cmp-nixpkgs
Contains two sources:
* `nixpkgs` for pkgs and lib
* `nixos` for nixos modules

Currently assumes that two flakes named `self` and `nixpkgs` are in the flake
registry, and that these flakes in turn outputs both `legacyPackages`
and `nixosConfigurations.$hostname`.

It's recommended to pin `nixpkgs` in your flake registry to avoid
potentially slow lookups of suggestions for `prev` and `super`. See [1]
for a way to do so.

NixOS module completion is only enabled for files under
`vim.fn.resolve('/etc/nixos/')`.

Depends on tree-sitter and https://github.com/nvim-treesitter/nvim-treesitter.

[1] https://discourse.nixos.org/t/my-painpoints-with-flakes/9750/14
