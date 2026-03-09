local M = {}

local start_type = "_"
local end_type = "$"

local config = {
	width = 0,
	marker = "",
}

function M.setup(opts)
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end
end

-- get comment prefix from 'commentstring'
local function get_comment_prefix()
	local cs = vim.bo.commentstring

	if not cs or cs == "" then
		return "//"
	end

	local prefix = cs:match("^(.*)%%s")
	if not prefix then
		return "//"
	end

	prefix = prefix:gsub("%s+$", "")
	return prefix
end


-- build section line
local function build_line(desc, line_type)
	local prefix = get_comment_prefix()

	local start = prefix .. " " .. config.marker .. " " .. line_type .. desc .. line_type .. " "
	local ending = " " .. prefix

	local dash_count = config.width - #start - #ending
	if dash_count < 1 then
		dash_count = 1
	end

	return start .. string.rep("-", dash_count) .. ending
end


-- create section
function M.create(desc)
	if not desc or desc == "" then
		desc = vim.fn.input("Section name: ")
		if desc == "" then
			return
		end
	end

	local line1 = build_line(desc, start_type)
	local line2 = build_line(desc, end_type)

	vim.api.nvim_put({ line1 }, "l", true, true)
	vim.api.nvim_put({ line2 }, "l", true, true)
	vim.cmd("normal! O")
	vim.cmd("normal! S")
end

-- detect section lines
local function is_section_begin(line)
	return line:match(config.marker .. " [_].*[_]")
end

local function is_section_end(line)
	return line:match(config.marker .. " [$].*[$]")
end


-- collect sections
local function get_sections()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local sections = {}

	for i, line in ipairs(lines) do
		if is_section_begin(line) then
			table.insert(sections, {
				line = i,
				text = line
			})
		end
	end

	return sections
end


-- jump to section
function M.jump()
	local sections = get_sections()

	if #sections == 0 then
		print("No sections found")
		return
	end

	local items = {}
	for _, s in ipairs(sections) do
		table.insert(items, s.text)
	end

	vim.ui.select(items, { prompt = "Jump to section" }, function(_, idx)
		if not idx then
			return
		end

		vim.api.nvim_win_set_cursor(0, { sections[idx].line, 0 })
	end)
end

function M.jump_end()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

	for i, l in ipairs(lines) do
		if is_section_end(l) then
			vim.api.nvim_win_set_cursor(0, { line + i, 0 })
			return
		end
	end
end

-- delete section under cursor
function M.delete()
	local line_nr = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()

	if not is_section_begin(line) then
		print("Not on a section line")
		return
	end

	vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, {})
end

function M.next_section()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

	for i, l in ipairs(lines) do
		if is_section_begin(l) then
			vim.api.nvim_win_set_cursor(0, { line + i, 0 })
			return
		end
	end
end

function M.prev_section()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)

	for i = #lines, 1, -1 do
		if is_section_begin(lines[i]) then
			vim.api.nvim_win_set_cursor(0, { i, 0 })
			return
		end
	end
end

local function find_section_bounds()
	local cursor = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local start_line = nil
	local end_line = nil

	for i = cursor, 1, -1 do
		if is_section_begin(lines[i]) then
			start_line = i
			break
		end
	end

	if not start_line then
		return nil
	end

	for i = start_line + 1, #lines do
		if is_section_end(lines[i]) then
			end_line = i
			break
		end
	end

	if not end_line then
		return nil
	end

	return start_line, end_line
end

function M.textobj_inner()
	local s, e = find_section_bounds()
	if not s then return end

	vim.fn.setpos("'<", { 0, s + 1, 1, 0 })
	vim.fn.setpos("'>", { 0, e - 1, 1, 0 })

	vim.cmd("normal! gv")
end

function M.textobj_around()
	local s, e = find_section_bounds()
	if not s then return end

	local col = vim.fn.col({ e, "$" })

	vim.fn.setpos("'<", { 0, s, 1, 0 })
	vim.fn.setpos("'>", { 0, e, col, 0 })

	vim.cmd("normal! gv")
end

return M
