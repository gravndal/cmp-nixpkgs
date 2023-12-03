-- TODO: tests for treesitter context
-- TODO(maybe): overrideAttrs (foo: { bar = foo.bar + "baz"; })
-- TODO(maybe): rec {}, let in, and what have you
-- TODO(probably not): support completing the ouput of any flake

local cmp = require('cmp')

local nixpkgs = {}
local hostname = vim.fn.hostname()
local configPrefix = 'self#nixosConfigurations.' .. hostname .. '.'
local manix = require('cmp_nixpkgs.utils.manix')
local nix = require('cmp_nixpkgs.utils.nix')
local overlay = vim.g.cmp_nixpkgs_overlay
  or vim.fn.resolve('/etc/nixos/') .. 'overlay'

nixpkgs.new = function()
  return setmetatable({}, { __index = nixpkgs })
end

nixpkgs.is_available = function()
  return vim.bo.filetype == 'nix'
end

nixpkgs.get_debug_name = function()
  return 'nixpkgs'
end

nixpkgs.get_keyword_pattern = function()
  return [[\w\+]]
end

nixpkgs.get_trigger_characters = function()
  return { '.' }
end

local function get_context(type, depth)
  local node = require('nvim-treesitter.ts_utils').get_node_at_cursor()
  if not node then return '' end
  depth = depth or 1
  local context = ''
  while node do
    if node:type() == type then
      if depth > 0 then
        depth = depth - 1
        context = vim.treesitter.get_node_text(node:named_child(0), 0)
          .. '.'
          .. context
      else
        break
      end
    end
    node = node:parent()
  end
  return context or ''
end

nixpkgs.complete = function(self, request, callback)
  local tokens = vim.split(request.context.cursor_before_line, '%s+')
  local last_token = tokens[#tokens]:gsub('^[%(%[{]+', '')
  self.flake = 'self'
  if
    not (
      last_token:find('^pkgs%.')
      or last_token:find('^lib%.')
      or last_token:find('^config%.')
    )
  then
    last_token = get_context('with_expression', 4)
      .. get_context('inherit_from')
      .. last_token
    if vim.startswith(vim.api.nvim_buf_get_name(0), overlay) then
      for _, root in ipairs({ 'final', 'prev', 'self', 'super' }) do
        if vim.startswith(last_token, root) then
          last_token = last_token:gsub('^' .. root .. '%.', 'pkgs.')
          self.flake = (root == 'prev' or root == 'super') and 'nixpkgs'
            or self.flake
          break
        end
      end
    end
  end
  if last_token:find('^pkgs%.') or last_token:find('^lib%.') then
    self.prefix = self.flake .. '#' .. last_token:match('.*%.')
    local prefixLen = #self.prefix + 1
    nix.get_completions(
      self.flake .. '#' .. last_token,
      callback,
      prefixLen,
      { cmp = { kind_text = 'Attr' } }
    )
  elseif last_token:find('^config%.') then
    self.prefix = configPrefix .. last_token:match('.*%.')
    local prefixLen = #self.prefix + 1
    nix.get_completions(
      configPrefix .. last_token,
      callback,
      prefixLen,
      { cmp = { kind_text = 'Attr' } }
    )
  else
    return callback()
  end
end

nixpkgs.resolve = function(self, completion_item, callback)
  if not cmp.get_active_entry() then return callback(completion_item) end

  if
    vim.startswith(self.prefix, self.flake .. '#lib.')
    or vim.startswith(self.prefix, self.flake .. '#pkgs.lib.')
  then
    if manix.query then
      local query = self.prefix:gsub('.*lib%.', '') .. completion_item.label
      return manix.query(query, 'nixpkgs_comments', completion_item, callback)
    end
    return callback(completion_item)
  end

  nix.get_metadata(
    self.prefix .. completion_item.label,
    completion_item,
    callback
  )
end

cmp.register_source('nixpkgs', nixpkgs.new())
