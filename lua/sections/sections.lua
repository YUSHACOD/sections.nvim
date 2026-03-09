local comment = require("sections.comment")
local format = require("sections.format")
local util = require("sections.util")

local M = {}

local start_type = "start"
local end_type = "end"

local config = {
	width = 0,
	marker = "",
}

---Configure section behaviour (marker, width, etc.).
---@param opts table?
function M.setup(opts)
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end
end

---Build a single section boundary line for the current buffer.
---@param desc string
---@param line_type string
---@param indent string
---@param indent_width integer
---@return string
local function build_line(desc, line_type, indent, indent_width)
	local parts = comment.parts(0)
	return format.boundary_line(config, parts, desc, line_type, indent, indent_width)
end


-- create section
function M.create(desc)
	if not desc or desc == "" then
		desc = vim.fn.input("Section name: ")
		if desc == "" then
			return
		end
	end

	local cur = vim.api.nvim_win_get_cursor(0)
	local line_nr = cur[1]
	local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1] or ""
	local indent = line:match("^(%s*)") or ""
	local indent_width = vim.fn.strdisplaywidth(indent)

	local line1 = build_line(desc, start_type, indent, indent_width)
	local line2 = build_line(desc, end_type, indent, indent_width)

	-- Top-level sections get a full block (start + end). Nested scopes only
	-- get a single header line to avoid visual noise.
	if indent_width > 0 then
		vim.api.nvim_put({ line1 }, "l", true, true)
		vim.cmd("normal! o")
		vim.cmd("normal! S")
	else
		vim.api.nvim_put({ line1 }, "l", true, true)
		vim.api.nvim_put({ line2 }, "l", true, true)
		vim.cmd("normal! O")
		vim.cmd("normal! S")
	end
end

-- strip comment delimiters so detection is independent of language.
---@param line string
---@return string
local function core_from_line(line)
	local parts = comment.parts(0)
	local left_raw = parts.left
	local right_raw = parts.right ~= "" and parts.right or nil

	local left = util.pesc(left_raw)
	local right = right_raw and util.pesc(right_raw) or nil

	line = line:gsub("^%s*" .. left .. "%s*", "", 1)
	if right then
		-- block comments: strip trailing suffix (e.g. "-->", "*/")
		line = line:gsub("%s*" .. right .. "%s*$", "", 1)
	else
		-- line comments: strip mirrored prefix at the end (e.g. "// ... //")
		line = line:gsub("%s*" .. left .. "%s*$", "", 1)
	end

	return util.trim(line)
end

-- detect section lines
local function is_section_begin(line)
	local core = core_from_line(line)
	-- "Title : ----- (marker)"
	local marker = util.pesc(config.marker)
	return core:match("^%s*.-%s:%s*-+%s+" .. marker .. "%s*$") ~= nil
end

local function is_section_end(line)
	local core = core_from_line(line)
	-- "(marker) ----- : Title"
	local marker = util.pesc(config.marker)
	return core:match("^%s*" .. marker .. "%s+-+%s:%s*.+%s*$") ~= nil
end

---Extract human-readable title from a start boundary line.
---@param line string
---@return string|nil
local function extract_title_from_begin(line)
	local core = core_from_line(line)
	local marker = util.pesc(config.marker)
	local title = core:match("^%s*(.-)%s:%s*-+%s+" .. marker .. "%s*$")
	if not title or title == "" then
		return nil
	end
	return util.trim(title)
end


-- collect sections
---Return all section starts in the current buffer.
---@return {line:integer,text:string,title:string}[]
local function get_sections()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	local sections = {}

	---Extract human-readable title from a boundary line.
	---@param line string
	---@return string
	local function section_title(line)
		local title = extract_title_from_begin(line)
		if not title or title == "" then
			return util.trim(line)
		end
		return util.trim(title)
	end

	for i, line in ipairs(lines) do
		if is_section_begin(line) then
			table.insert(sections, {
				line = i,
				text = line,
				title = section_title(line),
			})
		end
	end

	return sections
end

---Telescope picker for sections (optional dependency).
---Lists all section starts and jumps to the selected one.
function M.telescope()
	local ok, pickers = pcall(require, "telescope.pickers")
	if not ok then
		util.notify("telescope.nvim not found (required for :SecTelescope)", vim.log.levels.WARN)
		return
	end

	local sections = get_sections()
	if #sections == 0 then
		util.notify("No sections found", vim.log.levels.INFO)
		return
	end

	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local picker_opts = {}

	-- optional themed layout
	if config.telescope_theme then
		local ok_theme, themes = pcall(require, "telescope.themes")
		if ok_theme then
			local getter = themes["get_" .. config.telescope_theme]
			if type(getter) == "function" then
				picker_opts = getter({})
			end
		end
	end

	pickers.new(picker_opts, {
		prompt_title = "Sections",
		finder = finders.new_table({
			results = sections,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry.title or entry.text,
					ordinal = entry.title or entry.text,
					lnum = entry.line,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			local function goto_selection()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if not selection or not selection.value then
					return
				end
				vim.api.nvim_win_set_cursor(0, { selection.value.line, 0 })
			end

			map("i", "<CR>", goto_selection)
			map("n", "<CR>", goto_selection)
			return true
		end,
	}):find()
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
		table.insert(items, s.title or s.text)
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

-- delete section under cursor
function M.delete()
	local start_line, end_line = find_section_bounds()
	if not start_line then
		print("No section around cursor")
		return
	end

	-- delete the entire section block, including boundaries
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, {})
end

---Rename the top-level section that the cursor is currently inside.
---If the cursor is not within any non-indented (full) section block,
---prints a friendly message and does nothing.
function M.rename()
	local cur_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	if cur_line > #lines then
		return
	end

	-- Find the nearest top-level (no-indent) section start at or above the cursor.
	local start_idx = nil
	for i = cur_line, 1, -1 do
		if is_section_begin(lines[i]) then
			local indent = lines[i]:match("^(%s*)") or ""
			if vim.fn.strdisplaywidth(indent) == 0 then
				start_idx = i
				break
			end
		end
	end

	if not start_idx then
		util.notify("Not inside any section to rename", vim.log.levels.WARN)
		return
	end

	-- Find matching end boundary for this top-level block.
	local end_idx = nil
	for i = start_idx + 1, #lines do
		if is_section_end(lines[i]) then
			end_idx = i
			break
		end
	end

	-- If there's no end boundary or cursor lies outside the block, treat as "not inside".
	if not end_idx or cur_line < start_idx or cur_line > end_idx then
		util.notify("Not inside any section to rename", vim.log.levels.WARN)
		return
	end

	local start_line_text = lines[start_idx]
	local indent = start_line_text:match("^(%s*)") or ""

	local old_title = extract_title_from_begin(start_line_text) or ""
	local new_title = vim.fn.input("New section name: ", old_title)
	if new_title == "" or new_title == old_title then
		return
	end

	local parts = comment.parts(0)
	local indent_width = vim.fn.strdisplaywidth(indent)

	-- replace start boundary
	local new_start = format.boundary_line(config, parts, new_title, start_type, indent, indent_width)
	vim.api.nvim_buf_set_lines(0, start_idx - 1, start_idx, false, { new_start })

	-- replace matching end boundary (we already know end_idx is valid)
	local end_line_text = lines[end_idx]
	local end_indent = end_line_text:match("^(%s*)") or ""
	local end_indent_width = vim.fn.strdisplaywidth(end_indent)
	local new_end = format.boundary_line(config, parts, new_title, end_type, end_indent, end_indent_width)
	vim.api.nvim_buf_set_lines(0, end_idx - 1, end_idx, false, { new_end })
end

return M
