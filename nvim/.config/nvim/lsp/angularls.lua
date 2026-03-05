-- Angular LS config lives in plugin/angularls.lua
-- It uses vim.lsp.start() directly because angularls needs dynamic cmd
-- computation (probe dirs depend on the resolved project root).
return {}
