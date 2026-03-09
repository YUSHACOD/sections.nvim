local M = {}

---@param msg string
---@param level? integer
function M.notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "sections.nvim" })
end

---@param s string?
---@return string
function M.trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

---@param s string
---@return integer
function M.display_width(s)
	return vim.fn.strdisplaywidth(s)
end

---@param s string
---@return string
function M.pesc(s)
	if vim.pesc then
		return vim.pesc(s)
	end
	return (s:gsub("([^%w])", "%%%1"))
end

return M
