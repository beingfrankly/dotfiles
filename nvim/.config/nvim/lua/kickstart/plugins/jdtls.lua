-- nvim-java: batteries-included Java development
-- Manages JDTLS, Lombok, java-debug, java-test, and Spring Boot tools
-- Does NOT use Mason for Java tools — has its own package manager
return {
  {
    'nvim-java/nvim-java',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'mfussenegger/nvim-dap',
      'JavaHello/spring-boot.nvim',
    },
    config = function()
      require('java').setup({
        jdk = {
          auto_install = false, -- JDK managed via ASDF
        },
      })
      vim.lsp.enable('jdtls')
    end,
  },
}
