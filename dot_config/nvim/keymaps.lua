-- Function to remap keys using an array of pairs
local function remap_keys(mode, key_pairs)
  for _, pair in ipairs(key_pairs) do
    local original_key, new_key = pair[1], pair[2]
    vim.api.nvim_set_keymap(mode, new_key, original_key, { noremap = true, silent = true })
  end
end

-- Define the key mappings as an array of pairs
local key_pairs = {
  { 'h', 'n' }, -- old key 'h' will now map to new key 'n'
  { 'j', 'e' }, -- old key 'j' will now map to new key 'e'
  { 'k', 'i' }, -- old key 'k' will now map to new key 'i'
  { 'l', 'o' }, -- old key 'l' will now map to new key 'o'
}

-- Apply the remapping across specified modes
local modes = { 'n', 'v', 'o' } -- Normal, Visual, Operator-pending modes
for _, mode in ipairs(modes) do
  remap_keys(mode, key_pairs)
end
