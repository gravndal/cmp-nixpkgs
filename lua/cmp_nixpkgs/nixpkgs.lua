-- TODO: define proper keyword_pattern and remove '{[ ' from trigger_characters
-- TODO: tests for treesitter context
-- TODO(maybe): overrideAttrs (foo: { bar = foo.bar + "baz"; })
-- TODO(maybe): rec {}, let in, and what have you
-- TODO(maybe): add docs to completion_item in nixpkgs.resolve()
-- TODO(maybe): set appropriate completionKind
-- TODO(probably not): support completing the ouput of any flake. This
-- technically isn't actually that hard to do if we supply the required
-- flake#prefix combo to the hypothetical setup function

local nixpkgs = {}

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
  return { '.', '(', '[', ' ' }
end

local function get_context(type, depth)
  local node = require('nvim-treesitter.ts_utils').get_node_at_cursor()
  if not node then return end
  depth = depth or 1
  local context = ''
  while node do
    if node:type() == type then
      if depth > 0 then
        depth = depth - 1
        context = vim.treesitter.query.get_node_text(node:named_child(0), 0) .. '.' .. context
      else
        break
      end
    end
    node = node:parent()
  end
  return context or ''
end

nixpkgs.complete = function(_, request, callback)
  local tokens = vim.split(request.context.cursor_before_line, '%s+')
  local last_token = tokens[#tokens]:gsub('^[%(%[{]+', '')
  if not last_token:find('^pkgs%.') or last_token:find('^lib%.') then
    last_token = get_context('with_expression', 4) .. get_context('inherit_from') .. last_token
    for _, root in ipairs({ 'final', 'prev', 'self', 'super', }) do
      last_token = last_token:gsub('^' .. root .. '%.', 'pkgs.')
    end
  end
  if last_token:find('^pkgs%.') or last_token:find('^lib%.') then
    vim.fn.jobstart({ 'nix', 'eval', 'self#' .. last_token }, {
      clear_env = true,
      env = { NIX_GET_COMPLETIONS = 2, },
      stdout_buffered = true,
      on_stdout = function(_, data)
        if #data < 3 then return callback() end
        local t = {}
        for i = 2, #data - 1 do -- first and last elements are always "attrs" and ""
          t[#t + 1] = { label = vim.trim(data[i]:sub(6 + #last_token)) }
        end
        return callback(t)
      end
    })
  else
    return callback()
  end
end

require('cmp').register_source('nixpkgs', nixpkgs.new())
