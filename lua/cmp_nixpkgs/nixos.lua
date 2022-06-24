-- TODO: tests for treesitter context
-- TODO(maybe): set appropriate completionKind for leaf attributes
-- TODO(maybe): add docs to completion_item in nixos.resolve()

local nixos = {}
local hostname = vim.fn.hostname()
local modulesPrefixLen = 34 + hostname:len()
local nixosConfigPath = vim.fn.resolve('/etc/nixos/')
local completionKind = require('cmp.types.lsp').CompletionItemKind.Module

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
  local depth = 5
  local context = ''
  while node do
    if depth > 0 then
      depth = depth - 1
      -- It looks like, based on a very casual look at the TSPlayground, that
      -- relevant attrpaths are always the siblings of parent nodes when going
      -- up the tree.
      local sibling = node:prev_named_sibling()
      if sibling and sibling:type() == 'attrpath' then
        context = vim.treesitter.query.get_node_text(sibling, 0) .. '.' .. context
      end
    end
    node = node:parent()
  end
  return context or ''
end

nixos.complete = function(_, request, callback)
  local tokens = vim.split(request.context.cursor_before_line, '%s+')
  local context = get_context()
  local last_token = context .. tokens[#tokens]:gsub('^[%(%[{]+', '')
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
            label = vim.trim(data[i]:sub(#context + modulesPrefixLen)),
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

require('cmp').register_source('nixos', nixos.new())
