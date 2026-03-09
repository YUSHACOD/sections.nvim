local util = require("sections.util")

local M = {}

---@param left string
---@param s string
---@return string
local function with_left(left, s)
  return left .. " " .. s
end

---Build a single boundary line around a section.
---Keeps the current marker / decorator layout while handling block comments.
---@param cfg table
---@param comment_parts {left:string, right:string}
---@param desc string
---@param line_type string -- "_" for top, "$" for bottom
---@return string
function M.boundary_line(cfg, comment_parts, desc, line_type)
  local left = comment_parts.left
  local right = comment_parts.right

  local lt = line_type or "_"
  local middle = ("%s %s%s%s "):format(cfg.marker, lt, desc, lt)
  local start = with_left(left, middle)

  -- For line comments we mirror the prefix on the right (e.g. "# ... #").
  -- For block comments (HTML, /* */) we use the trailing part.
  local ending = right ~= "" and (" " .. right) or (" " .. left)

  local dash_count = cfg.width - util.display_width(start) - util.display_width(ending)
  if dash_count < 1 then
    dash_count = 1
  end

  return start .. string.rep("-", dash_count) .. ending
end

return M
