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

return {
  cached = function()
    return manixCached
  end,
  query = function(query, source)
    return source and vim.fn.system({ 'manix', '-s', query, '--source', source, })
        or vim.fn.system({ 'manix', '-s', query, })
  end,
}
