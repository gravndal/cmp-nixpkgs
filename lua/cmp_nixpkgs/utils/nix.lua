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
  vim.fn.jobstart({
    'nix',
    'eval',
    '--read-only',
    '--json',
    query .. '.meta',
  }, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, meta)
      meta = table.concat(meta, '\n')
      if #meta == 0 then return end
      meta = vim.json.decode(meta)
      local t = {
        meta.description and vim.trim(meta.description) .. '\n' or '',
        meta.longDescription and vim.trim(meta.longDescription) .. '\n' or '',
        meta.name and 'NAME: ' .. vim.trim(meta.name) or '',
        meta.broken and 'NOTE: Marked as broken' or '',
        meta.insecure and 'WARN: Marked as insecure' or '',
      }
      local licenses = meta.license
          and ({ meta.license.fullName } or vim.tbl_map(function(e)
            return e.fullName
          end, meta.license))
        or {}
      for _, l in ipairs(licenses) do
        t[#t + 1] = 'LICENSE: ' .. l
      end
      completion_item.detail = table.concat(
        vim.tbl_filter(function(e)
          return e and e ~= ''
        end, t),
        '\n'
      )
      if callback then
        callback(completion_item)
        callback = nil
      end
    end,

    on_stderr = function(_, meta)
      meta = vim.tbl_filter(function(err)
        return not err:match([[^error %(ignored%)]])
      end, meta)
      meta = table.concat(meta, '\n')
      if #meta == 0 then return end

      if
        not meta:match([[^error: flake %S+ does not provide attribute]])
        and not meta:match([[^error: %S+ is not an attribute set]])
        and not meta:match([[^error: cannot convert a function to JSON]])
      then
        completion_item.detail = meta
      end
      if callback then
        callback(completion_item)
        callback = nil
      end
    end,

    on_exit = function()
      if callback then callback(completion_item) end
    end,
  })
end

return M
