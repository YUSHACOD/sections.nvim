local util = require("sections.util")

local M = {}

---@param left string
---@param s string
---@return string
local function with_left(left, s)
	return left .. " " .. s
end

---Build a single boundary line around a section.
---@param cfg table
---@param comment_parts {left:string, right:string}
---@param desc string
---@param line_type string -- "start" or "end"
---@return string
function M.boundary_line(cfg, comment_parts, desc, line_type)
	local left = comment_parts.left
	local right = comment_parts.right
	local ending = right ~= "" and (" " .. right) or (" " .. left)

	if line_type == "end" then
		-- "//  (marker) ------------- : Title //"
		local base = (" %s "):format(cfg.marker)
		local start = with_left(left, base)
		local tail = (" : %s "):format(desc)

		local dash_count = cfg.width - util.display_width(start) - util.display_width(tail) - util.display_width(ending)
		if dash_count < 1 then
			dash_count = 1
		end

		return start .. string.rep("-", dash_count) .. tail .. ending
	end

	-- default: start boundary
	-- "//  Title : ------------- (marker) //"
	local middle = (" %s : "):format(desc)
	local start = with_left(left, middle)
	local tail = (" %s "):format(cfg.marker)

	-- For line comments we mirror the prefix on the right (e.g. "# ... #").
	-- For block comments (HTML, /* */) we use the trailing part.
	local dash_count = cfg.width - util.display_width(start) - util.display_width(tail) - util.display_width(ending)
	if dash_count < 1 then
		dash_count = 1
	end

	return start .. string.rep("-", dash_count) .. tail .. ending
end

return M
