local completionKind = require('cmp.types.lsp').CompletionItemKind.Text

return {
  get_completions = function(query, callback, trunc, kind)
    vim.fn.jobstart({ 'nix', 'eval', '--read-only', query }, {
      clear_env = true,
      env = { NIX_GET_COMPLETIONS = 3, },
      stdout_buffered = true,
      on_stdout = function(_, data)
        if #data < 3 then return callback() end
        local t = {}
        for i = 2, #data - 1 do -- first and last elements are always "attrs" and ""
          t[#t + 1] = {
            label = vim.trim(data[i]:sub(trunc)),
            kind = kind or completionKind,
          }
        end
        return callback(t)
      end
    })
  end
}
