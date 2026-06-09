-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	pattern = "*",
	desc = "highlight selection on yank",
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- open help in vertical split
vim.api.nvim_create_autocmd("FileType", {
	pattern = "help",
	command = "wincmd L",
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
	command = "wincmd =",
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("no_auto_comment", {}),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
	pattern = { ".env", ".env.*" },
	callback = function()
		vim.bo.filetype = "dosini"
	end,
})

-- show cursorline only in active window enable
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("active_cursorline", { clear = true }),
	callback = function()
		vim.opt_local.cursorline = true
	end,
})

-- show cursorline only in active window disable
vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
	group = "active_cursorline",
	callback = function()
		vim.opt_local.cursorline = false
	end,
})

-- ide like highlight when stopping cursor
vim.api.nvim_create_autocmd("CursorMoved", {
	group = vim.api.nvim_create_augroup("LspReferenceHighlight", { clear = true }),
	desc = "Highlight references under cursor",
	callback = function()
		-- Only run if the cursor is not in insert mode
		if vim.fn.mode() ~= "i" then
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			local supports_highlight = false
			for _, client in ipairs(clients) do
				if client.server_capabilities.documentHighlightProvider then
					supports_highlight = true
					break -- Found a supporting client, no need to check others
				end
			end

			-- 3. Proceed only if an LSP is active AND supports the feature
			if supports_highlight then
				vim.lsp.buf.clear_references()
				vim.lsp.buf.document_highlight()
			end
		end
	end,
})

-- ide like highlight when stopping cursor
vim.api.nvim_create_autocmd("CursorMovedI", {
	group = "LspReferenceHighlight",
	desc = "Clear highlights when entering insert mode",
	callback = function()
		vim.lsp.buf.clear_references()
	end,
})

-- auto create dir when saving a file where the directory doesn't exist
local function augroup(name)
  return vim.api.nvim_create_augroup('user_' .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = augroup('auto_create_dir'),
  callback = function(event)
    if event.match:match('^%w%w+:[/\\][/\\]') then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('close_with_q'),
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd('close')
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

-- fix conceallevel for json files
vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = augroup('json_conceal'),
  pattern = { 'json', 'jsonc', 'json5' },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- wrap and spell in text filetypes
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('wrap_spell'),
  pattern = { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- check if file changed outside of neovim
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd('checktime')
    end
  end,
})

-- make man pages unlisted (easier to close)
vim.api.nvim_create_autocmd('FileType', {
  group = augroup('man_unlisted'),
  pattern = { 'man' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})
