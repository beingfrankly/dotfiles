local ok, ls = pcall(require, 'luasnip')
if not ok then
  vim.notify(ls, vim.log.levels.ERROR)
end

local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node

return {
  typescript = {
    -- This snippet will only trigger for `.spec.ts` files
    s('spec-comp', {
      t "import { Spectator, createComponentFactory } from '@ngneat/spectator';",
      t 'import { ',
      i(1, 'name'),
      t "Component } from './",
      i(2, 'path'),
      t ".component';",
      t '',
      t "describe('",
      i(1, 'name'),
      t "Component', () => {",
      t '  let spectator: Spectator<',
      i(1, 'name'),
      t 'Component>;',
      t '  const createComponent = createComponentFactory(',
      i(1, 'name'),
      t 'Component);',
      t '  ',
      t '  beforeEach(() => spectator = createComponent());',
      t '',
      t "  it('should ', () => {",
      t "    expect(spectator.query('button')).toHaveClass('success');",
      t '  });',
      t '});',
    }, { filetypes = { 'typescript', 'typescriptreact' } }), -- Restrict to TypeScript files only
  },
}
