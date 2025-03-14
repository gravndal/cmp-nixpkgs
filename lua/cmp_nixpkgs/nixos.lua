-- TODO: Optionally disable docs.
-- TODO(maybe): Set appropriate completionKind for leaf attributes.

local cmp = require('cmp')
local completionKind = require('cmp.types.lsp').CompletionItemKind.Module

local nixos = {}
local hostname = vim.fn.hostname()
local modulesPrefixLen = 35 + hostname:len()
local nixosConfigPath = vim.fn.resolve('/etc/nixos/')
local manix = require('cmp_nixpkgs.utils.manix')

nixos.new = function()
  return setmetatable({}, { __index = nixos })
end

nixos.is_available = function()
  return vim.bo.filetype == 'nix'
    and vim.startswith(vim.fn.resolve(vim.fn.expand('%:p')), nixosConfigPath)
end

nixos.get_debug_name = function()
  return 'nixos'
end

nixos.get_keyword_pattern = function()
  return [[\w\+]]
end

nixos.get_trigger_characters = function()
  return { '.' }
end

local function get_context(abort)
  local node = vim.treesitter.get_node()
  if not node then return '' end
  local context = ''
  while node do
    if abort and node:type() == abort then break end
    -- It looks like, based on a very casual look at the TSPlayground, that
    -- relevant attrpaths are always the siblings of parent nodes when going
    -- up the tree.
    local sibling = node:prev_named_sibling()
    if sibling and sibling:type() == 'attrpath' then
      context = vim.treesitter.get_node_text(sibling, 0) .. '.' .. context
    end
    node = node:parent()
  end
  return context or ''
end

nixos.complete = function(self, request, callback)
  local tokens = vim.split(request.context.cursor_before_line, '%s+')
  if vim.fn.expand('%:t') == 'flake.nix' then
    self.context = get_context('function_expression')
  else
    self.context = get_context()
  end
  local last_token = (self.context .. tokens[#tokens]:gsub('^[%(%[{]+', ''))
  local prefixLen = #self.context + modulesPrefixLen
  require('cmp_nixpkgs.utils.nix').get_completions(
    table.concat({ 'self#nixosConfigurations', hostname, 'options', last_token, }, '.'),
    callback, prefixLen, { kind = completionKind }
  )
end

nixos.resolve = function(self, completion_item, callback)
  if not cmp.get_active_entry() then return callback(completion_item) end
  if manix.query then
    -- NOTE: This query wont provide docs for descendants of <name>-attributes.
    local query = self.context .. completion_item.label
    if query:find('%.') then -- ignore top level attributes
      return manix.query(query, 'nixos_options', completion_item, callback)
      -- TODO: Optionally only show documentation for leaf attributes.
      --
      -- Asking for completions for child attributes can be used as a heuristic
      -- if we also have a special allowance for `package`-attributes which are
      -- typically derivations.
      --
      -- if #vim.fn.system({
      --   'env', '-i', 'NIX_GET_COMPLETIONS=2', 'nix', 'eval',
      --   table.concat(
      --     { 'self#nixosConfigurations', hostname, 'config', query, '' }, '.'
      --   )
      -- }) == 6 or vim.endswith(query, 'package') then
      --   completion_item.detail = vim.fn.system({
      --     'manix', '-s', query, '--source', 'nixos_options',
      --   }):gsub('^NixOS Options\n.-\n.-\n', '')
      -- end
    end
  end
  callback(completion_item)
end

cmp.register_source('nixos', nixos.new())
