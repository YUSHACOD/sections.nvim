local M = {}

M.defaults = {
  -- total visual width of the boundary line
  width = 100,
  -- marker text embedded into section boundaries (kept in sync with init.lua)
  marker = "(section)",
  -- Telescope theme name (e.g. "dropdown", "ivy"); nil for raw layout
  telescope_theme = "dropdown",
  -- default keymaps (match current behaviour)
  keymaps = {
    next = "]s",
    prev = "[s",
    ["end"] = "<leader>es",
    create = "<leader>sc",
    jump = "<leader>sj",
    delete = "<leader>sd",
    telescope = "<leader>ss",
  },
  -- whether to register textobjects (is / as)
  textobjects = true,
  -- whether to create :Sec* user commands
  commands = true,
  -- if true, next/prev wrap around the buffer (unused for now)
  wrap_navigation = false,
}

---@param user table?
---@return table
function M.normalize(user)
  local cfg = vim.tbl_deep_extend("force", {}, M.defaults, user or {})

  if type(cfg.width) ~= "number" or cfg.width < 20 then
    cfg.width = M.defaults.width
  end
  if type(cfg.marker) ~= "string" or cfg.marker == "" then
    cfg.marker = M.defaults.marker
  end

  return cfg
end

return M
