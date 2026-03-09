local comment = require("sections.comment")
local format = require("sections.format")
local util = require("sections.util")

local M = {}

local start_type = "_"
local end_type = "$"

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
---@return string
local function build_line(desc, line_type)
	local parts = comment.parts(0)
	return format.boundary_line(config, parts, desc, line_type)
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
	local marker = util.pesc(config.marker)
	return line:match(marker .. " [_].*[_]")
end

local function is_section_end(line)
	local marker = util.pesc(config.marker)
	return line:match(marker .. " [$].*[$]")
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
		local marker = util.pesc(config.marker)
		-- matches: "<marker> _Title_"
		local pat = marker .. " " .. util.pesc(start_type) .. "(.-)" .. util.pesc(start_type)
		local title = line:match(pat)
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

	pickers.new({}, {
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

return M
