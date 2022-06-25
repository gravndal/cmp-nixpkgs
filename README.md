# cmp-nixpkgs
Contains two sources:
* `nixpkgs` for pkgs and lib.
* `nixos` for nixos modules.

Currently assumes that two flakes named `self` and `nixpkgs` are in the flake
registry, and that these flakes in turn both output `legacyPackages`.

It's recommended to pin `nixpkgs` in your flake registry to avoid potentially
slow lookups of suggestions for `prev` and `super`. See [1] for a way to do so.

NixOS module completion is only enabled for files under
`vim.fn.resolve('/etc/nixos/')`. It suggests attributes paths found under
`config`[2], this means that it will provide suggestions matching your
currently running system. If you have `manix` in your `PATH`, it will be used
to resolve documentation.

Depends on tree-sitter and https://github.com/nvim-treesitter/nvim-treesitter.

[1] https://discourse.nixos.org/t/my-painpoints-with-flakes/9750/14

[2] More accurately `self#nixosConfigurations.$hostname.config`.
