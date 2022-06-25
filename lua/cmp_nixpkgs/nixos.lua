-- TODO: Tests for treesitter context.
-- TODO: Optionally disable docs.
-- TODO(maybe): Set appropriate completionKind for leaf attributes.

local nixos = {}
local hostname = vim.fn.hostname()
local modulesPrefixLen = 34 + hostname:len()
local nixosConfigPath = vim.fn.resolve('/etc/nixos/')
local completionKind = require('cmp.types.lsp').CompletionItemKind.Module
local manixCached = false

if vim.fn.executable('manix') then
  vim.fn.jobstart({
    'manix', 'programs.less', '--source', 'nixos_options',
  }, {
    on_exit = function()
      if vim.v.shell_error == 0 then
        manixCached = true
      end
    end
  })
end

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

local function get_context()
  local node = require('nvim-treesitter.ts_utils').get_node_at_cursor()
  if not node then return '' end
  local context = ''
  while node do
    -- It looks like, based on a very casual look at the TSPlayground, that
    -- relevant attrpaths are always the siblings of parent nodes when going
    -- up the tree.
    local sibling = node:prev_named_sibling()
    if sibling and sibling:type() == 'attrpath' then
      context = vim.treesitter.query.get_node_text(sibling, 0) .. '.' .. context
    end
    node = node:parent()
  end
  return context or ''
end

nixos.complete = function(self, request, callback)
  local tokens = vim.split(request.context.cursor_before_line, '%s+')
  self.context = get_context()
  local last_token = self.context .. tokens[#tokens]:gsub('^[%(%[{]+', '')
  if last_token ~= '' then
    vim.fn.jobstart({
      'nix', 'eval',
      table.concat({ 'self#nixosConfigurations', hostname, 'config', last_token, }, '.')
    }, {
      clear_env = true,
      env = { NIX_GET_COMPLETIONS = 2, },
      stdout_buffered = true,
      on_stdout = function(_, data)
        if #data < 3 then return callback() end
        local t = {}
        for i = 2, #data - 1 do -- first and last elements are always "attrs" and ""
          t[#t + 1] = {
            label = vim.trim(data[i]:sub(#self.context + modulesPrefixLen)),
            kind = completionKind,
          }
        end
        return callback(t)
      end
    })
  else
    return callback()
  end
end

nixos.resolve = function(self, completion_item, callback)
  if manixCached then
    -- NOTE: This query wont provide docs for dependents of <name>-attributes.
    local query = self.context .. completion_item.label
    if query:find('%.') then -- ignore top level attributes
      completion_item.detail = vim.fn.system({
        'manix', '-s', query, '--source', 'nixos_options',
      })

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

require('cmp').register_source('nixos', nixos.new())
