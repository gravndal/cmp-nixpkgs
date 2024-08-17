local M = {}

if vim.fn.executable('manix') ~= 0 and vim.fn.executable('pwait') ~= 0 then
  -- wait on running instances of manix before calling function
  local function pwait(fn)
    vim.system({ 'pwait', '--exact', 'manix' }, {}, fn)
  end

  -- precache on startup if possible
  pwait(function()
    vim.system({
      'manix',
      'programs.less',
      '--source',
      'nixos_options',
    })
  end)

  M.query = function(query, source, completion_item, callback)
    pwait(function()
      vim.system(
        source and { 'manix', '-s', query, '--source', source }
          or { 'manix', '-s', query },
        {
          text = true,
        },
        function(obj)
          completion_item.detail = obj.stdout
          return callback(completion_item)
        end
      )
    end)
  end
end

return M
