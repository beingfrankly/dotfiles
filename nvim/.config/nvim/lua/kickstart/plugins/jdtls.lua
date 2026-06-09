require('java').setup {
  jdk = {
    auto_install = false, -- JDK managed via ASDF
  },
}
vim.lsp.enable('jdtls')
