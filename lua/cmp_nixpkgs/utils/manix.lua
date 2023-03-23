local M = {}

if vim.fn.executable('manix') ~= 0 and vim.fn.executable('pwait') ~= 0 then
  vim.fn.jobstart({
    'manix',
    'programs.less',
    '--source',
    'nixos_options',
  })

  M.query = function(query, source, completion_item, callback)
    local exec = source and { 'manix', '-s', query, '--source', source }
      or { 'manix', '-s', query }

    -- try to avoid running multiple instances of manix at once as generating
    -- the cache is quite expensive
    vim.fn.jobstart({ 'pwait', '--exact', 'manix' }, {
      on_exit = function()
        -- if we've just spent however many seconds waiting for manix and the
        -- completion menu is already closed, return early
        if not require('cmp').get_active_entry() then
          return callback(completion_item)
        end
        vim.fn.jobstart(exec, {
          clear_env = true,
          stdout_buffered = true,
          on_stdout = function(_, data)
            completion_item.detail = table.concat(data, '\n')
            return callback(completion_item)
          end,
        })
      end,
    })
  end
end

return M
