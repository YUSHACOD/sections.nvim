local util = require("sections.util")

local M = {}

---@class SectionsCommentParts
---@field left string
---@field right string

---Derive comment prefix/suffix from 'commentstring' for a buffer.
---Supports both line comments ("// %s") and block comments ("<!-- %s -->").
---@param bufnr integer
---@return SectionsCommentParts
function M.parts(bufnr)
	local cs = vim.bo[bufnr].commentstring
	if type(cs) ~= "string" or cs == "" then
		return { left = "//", right = "" }
	end

	local left, right = cs:match("^(.*)%%s(.*)$")
	if not left then
		return { left = "//", right = "" }
	end

	left = util.trim(left)
	right = util.trim(right or "")

	return { left = left ~= "" and left or "//", right = right }
end

return M
