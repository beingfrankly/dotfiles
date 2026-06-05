-- Build hooks for vim.pack
-- Runs post-install/update build steps via PackChanged autocmd

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind

    if kind ~= 'install' and kind ~= 'update' then
      return
    end

    if name == 'nvim-treesitter' then
      vim.cmd('TSUpdate')
    end

    if name == 'markdown-preview.nvim' then
      vim.fn['mkdp#util#install']()
    end
  end,
})
