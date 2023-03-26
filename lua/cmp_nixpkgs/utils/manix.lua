local M = {}

if vim.fn.executable('manix') ~= 0 and vim.fn.executable('pwait') ~= 0 then
  -- wait on running instances of manix before calling function
  local function pwait(fn)
    vim.fn.jobstart({ 'pwait', '--exact', 'manix' }, { on_exit = fn })
  end

  -- precache on startup if possible
  pwait(function()
    vim.fn.jobstart({
      'manix',
      'programs.less',
      '--source',
      'nixos_options',
    })
  end)

  M.query = function(query, source, completion_item, callback)
    pwait(function()
      -- return early if the completion menu is already closed
      if not require('cmp').get_active_entry() then
        return callback(completion_item)
      end
      vim.fn.jobstart(
        source and { 'manix', '-s', query, '--source', source }
          or { 'manix', '-s', query },
        {
          stdout_buffered = true,
          on_stdout = function(_, data)
            completion_item.detail = table.concat(data, '\n')
            return callback(completion_item)
          end,
        }
      )
    end)
  end
end

return M
