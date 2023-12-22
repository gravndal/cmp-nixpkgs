local M = {}
local completionKind = require('cmp.types.lsp').CompletionItemKind.Text

M.get_completions = function(query, callback, trunc, opts)
  vim.system({ 'nix', 'eval', '--read-only', query }, {
    env = { NIX_GET_COMPLETIONS = 3 },
    text = true,
  }, function(obj)
    if not obj.stdout then return callback() end

    local data = vim.split(obj.stdout, '\n')

    -- first and last elements are always "attrs" and ""
    if #data < 3 then return callback() end
    table.remove(data, 1)
    table.remove(data, #data)

    callback(vim.tbl_map(function(v)
      return {
        label = vim.trim(v:sub(trunc)),
        kind = opts and opts.kind or completionKind,
        cmp = opts and opts.cmp or nil,
      }
    end, data))
  end)
end

M.get_metadata = function(query, completion_item, callback)
  vim.system({
    'nix',
    'eval',
    '--read-only',
    '--json',
    query .. '.meta',
  }, { text = true }, function(obj)
    if obj.stderr and obj.stderr ~= '' then
      local err = obj.stderr:gsub([[^error %(ignored%).-$]], '')

      if
        err ~= ''
        and not err:match([[^error: flake %S+ does not provide attribute]])
        and not err:match([[^error: %S+ is not an attribute set]])
        and not err:match([[^error: cannot convert a function to JSON]])
      then
        return callback(
          vim.tbl_extend('error', completion_item, { detail = err })
        )
      end
    end

    if not obj.stdout or obj.stdout == '' then
      return callback(completion_item)
    end

    local out = vim.json.decode(obj.stdout)

    local t = {
      out.description and vim.trim(out.description) .. '\n' or '',
      out.longDescription and vim.trim(out.longDescription) .. '\n' or '',
      out.name and 'NAME: ' .. vim.trim(out.name) or '',
      out.broken and 'NOTE: Marked as broken' or '',
      out.insecure and 'WARN: Marked as insecure' or '',
    }

    if out.license then
      local function parse(license)
        if license.fullName then
          return table.insert(t, 'LICENSE: ' .. license.fullName)
        elseif type(license) == 'string' or type(license[1]) == 'string' then
          return table.insert(t, 'LICENSE: ' .. vim.inspect(license))
        elseif type(license) == 'table' then
          for _, l in ipairs(license) do
            parse(l)
          end
        end
      end
      parse(out.license)
    end

    t = vim.tbl_filter(function(e)
      return e and e ~= ''
    end, t)

    callback(vim.tbl_extend('error', completion_item, {
      detail = table.concat(t, '\n'),
    }))
  end)
end

return M
