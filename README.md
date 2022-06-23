# cmp-nixpkgs
Contains two sources:
* `nixpkgs` for pkgs and lib
* `nixos` for nixos modules

Currently assumes that some flake named `self` is in the flake registry,
and that this flake in turn outputs both `legacyPackages` and
`nixosConfigurations.$hostname`.

NixOS module completion is only enabled for files under
`vim.fn.resolve('/etc/nixos/')`.

Depends on tree-sitter and https://github.com/nvim-treesitter/nvim-treesitter.
