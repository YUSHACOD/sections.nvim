I want a neovim system that will create sections, this sections should be between the following lines " // <Description> ------------------------------- //" * 2. the width of this line should always be 100 regardless the size of the description. I want a function to create a section, a function to jump to section and a function to delete a section

if there something similar available notify me or make it

Short answer: there isn’t an existing Neovim plugin that exactly does “fixed-width section comment blocks + create/jump/delete sections.” Most comment plugins (like Comment.nvim) only toggle comments and motions, not structural sections.

But this is actually very easy to implement cleanly in Lua (~80–100 lines) and integrate with Telescope/quickfix later if you want.

Below is a minimal Neovim Lua system that does exactly what you asked:

    creates sections like
    // <Description> ------------------------------ //

    total width always = 100

    functions:

        create_section(desc)

        jump_section()

        delete_section()

1. Section format

Example output (always width 100):

 // Rendering Pipeline --------------------------------------------------------- //

Pattern used for detection:

^%s*// <.->

2. Lua implementation

Put this in:

~/.config/nvim/lua/sections.lua

local M = {}

local WIDTH = 100

local function build(desc)
    local prefix = "// <" .. desc .. "> "
    local suffix = " //"

    local dash_count = WIDTH - #prefix - #suffix
    if dash_count < 1 then dash_count = 1 end

    return prefix .. string.rep("-", dash_count) .. suffix
end

function M.create_section()
    local desc = vim.fn.input("Section name: ")
    if desc == "" then return end

    local line = build(desc)
    vim.api.nvim_put({line}, "l", true, true)
end

local function find_sections()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local sections = {}
    for i, line in ipairs(lines) do
        if line:match("^%s*// <.-%>") then
            table.insert(sections, {line = i, text = line})
        end
    end

    return sections
end

function M.jump_section()
    local sections = find_sections()

    if #sections == 0 then
        print("No sections found")
        return
    end

    local items = {}
    for _, s in ipairs(sections) do
        table.insert(items, s.text)
    end

    vim.ui.select(items, {prompt="Jump to section"}, function(choice, idx)
        if not choice then return end
        vim.api.nvim_win_set_cursor(0, {sections[idx].line, 0})
    end)
end

function M.delete_section()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local text = vim.api.nvim_get_current_line()

    if text:match("^%s*// <.-%>") then
        vim.api.nvim_buf_set_lines(0, line-1, line, false, {})
    else
        print("Not on a section line")
    end
end

return M

3. Keymaps

Add to init.lua:

local sec = require("sections")

vim.keymap.set("n", "<leader>sc", sec.create_section)
vim.keymap.set("n", "<leader>sj", sec.jump_section)
vim.keymap.set("n", "<leader>sd", sec.delete_section)

Example usage:

<leader>sc   create section
<leader>sj   jump section
<leader>sd   delete section

4. Example result

Typing:

<leader>sc
Rendering Pipeline

Creates:

 // <Rendering Pipeline> ------------------------------------------------------- //

Always exactly 100 characters.
5. Optional upgrades (worth doing)

If you want this to feel really powerful, we can add:
Telescope integration

Sections show in fuzzy picker.
motions

]s   next section
[s   previous section

fold sections

Sections automatically create folds.
auto regenerate width if description edited

💡 My suggestion: turn this into a tiny plugin (~150 LOC).
It’d be a genuinely useful Neovim plugin.

If you want, I can also give you a much nicer version with:

    Telescope jump

    next/prev section motions

    section folding

    multi-line section blocks

It becomes a seriously nice code navigation system.

can you instead of using // use the appropriate comment charachter for each language

Yes — the correct way to do this in Neovim is to read the buffer’s commentstring option. That option already stores the proper comment syntax for the current language (for example // %s, # %s, <!-- %s -->, etc.).

So instead of hardcoding //, we extract the comment prefix from vim.bo.commentstring.

Examples of commentstring:
Language	commentstring	prefix
C/C++	// %s	//
Python	# %s	#
Lua	-- %s	--
Vimscript	" %s	"
HTML	<!-- %s -->	<!--

Neovim automatically sets this when the filetype is detected.
Improved section system (language-aware comments)

Replace the section builder with this version.

local M = {}

local WIDTH = 100

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

local function build(desc)
    local prefix = get_comment_prefix()

    local start = prefix .. " <" .. desc .. "> "
    local ending = " " .. prefix

    local dash_count = WIDTH - #start - #ending
    if dash_count < 1 then dash_count = 1 end

    return start .. string.rep("-", dash_count) .. ending
end

function M.create_section()
    local desc = vim.fn.input("Section name: ")
    if desc == "" then return end

    local line = build(desc)
    vim.api.nvim_put({ line }, "l", true, true)
end

Example output in different languages
C / C++

 // <Renderer> ---------------------------------------------------------------- //

Python

 # <Renderer> ---------------------------------------------------------------- #

Lua

 -- <Renderer> --------------------------------------------------------------- --

Vimscript

 " <Renderer> ---------------------------------------------------------------- "

One small caveat (HTML etc.)

Languages with block comments like:

<!-- %s -->

would produce something like

<!-- <Section> ------------------------------- -->

If you want, we can make the script handle block comments properly too (detect both prefix + suffix).
Optional upgrades (this gets really nice)

I can also extend this system so that:

    ]s → next section

    [s → previous section

    Telescope picker for sections

    automatic folds for sections

    regenerate line length when editing description

    section rename

You basically get a structured code outline system inside Neovim.

If you want, I can also turn this into a clean 200-line plugin that feels native. It would actually be pretty slick.

yes I want to create this as a plugin, first only give me the setup to create a plugin, how does the directory look like how to include the plugin in my neovim config

Alright — let’s set up a proper Neovim plugin skeleton. This is the clean structure most Lua plugins use.

The key idea: anything in plugin/ runs automatically at startup, while Lua modules live in lua/ and are loaded with require().
1. Plugin directory structure

Suppose your plugin is called sections.nvim.

sections.nvim/
├── lua/
│   └── sections/
│       ├── init.lua
│       ├── commands.lua
│       └── sections.lua
│
├── plugin/
│   └── sections.lua
│
├── doc/
│   └── sections.txt
│
├── README.md
└── LICENSE

What each directory does

plugin/

plugin/sections.lua

    Auto-executed when Neovim starts

    Defines commands, keymaps, setup

    Should be very small

lua/

lua/sections/*.lua

    Actual plugin logic

    Loaded with:

require("sections")

Neovim searches the lua/ folder automatically when resolving require.

doc/

doc/sections.txt

    Vim help docs (:h sections.nvim)

2. Minimal working plugin
plugin loader

plugin/sections.lua

require("sections").setup()

This file runs automatically on startup.
main module

lua/sections/init.lua

local M = {}

function M.setup()
    vim.api.nvim_create_user_command(
        "SectionCreate",
        function()
            require("sections.sections").create()
        end,
        {}
    )
end

return M

logic file

lua/sections/sections.lua

local M = {}

function M.create()
    print("Create section called")
end

return M

3. Testing the plugin locally

Put the plugin somewhere like:

~/dev/sections.nvim

If you use lazy.nvim

Add this to your plugin list:

{
    dir = "~/dev/sections.nvim"
}

or

{
    "sections",
    dir = "~/dev/sections.nvim"
}

If you want manual loading (no plugin manager)

Put it in:

~/.local/share/nvim/site/pack/dev/start/sections.nvim

Neovim automatically loads plugins in pack/*/start/.
4. Run Neovim

Restart Neovim.

Then run:

:SectionCreate

You should see:

Create section called

Congrats — your plugin is loaded.
5. Recommended plugin layout (best practice)

As your plugin grows:

lua/sections/
├── init.lua
├── config.lua
├── sections.lua
├── navigation.lua
└── util.lua

This keeps things clean once the plugin hits ~500 lines.

💡 Since you’re building a section navigation plugin, the next step should be:

    create user commands

    implement section parser

    add motions (]s [s)

    add telescope integration

That will turn it into a seriously nice Neovim navigation tool.

If you want, I can also show you the real plugin architecture most popular Neovim plugins use (Treesitter / Telescope style) — it’s a slightly cleaner pattern than the basic one.

now lets start filling this stuff first give me the commands.lua

Alright, let’s build commands.lua properly. The idea is:

    This file only defines user commands

    It calls functions from the core module (sections.lua)

    Keeps command definitions clean and centralized

Think of it as the CLI layer of your plugin.
lua/sections/commands.lua

local M = {}

local function get_sections()
    return require("sections.sections")
end

function M.setup()
    local sec = get_sections()

    vim.api.nvim_create_user_command(
        "SectionCreate",
        function(opts)
            sec.create(opts.args)
        end,
        {
            nargs = "?",
            desc = "Create a new section"
        }
    )

    vim.api.nvim_create_user_command(
        "SectionJump",
        function()
            sec.jump()
        end,
        {
            desc = "Jump to a section"
        }
    )

    vim.api.nvim_create_user_command(
        "SectionDelete",
        function()
            sec.delete()
        end,
        {
            desc = "Delete the section under cursor"
        }
    )
end

return M

What this gives you

Commands available inside Neovim:

:SectionCreate
:SectionCreate Rendering
:SectionJump
:SectionDelete

Examples:

Create section interactively:

:SectionCreate

Create section directly:

:SectionCreate Renderer

Jump to section:

:SectionJump

Delete section under cursor:

:SectionDelete

Next step

Your init.lua should now call this.

lua/sections/init.lua

local M = {}

function M.setup()
    require("sections.commands").setup()
end

return M

If you want, next we should implement sections.lua, which will contain the real logic:

    comment detection (commentstring)

    section line builder (100 chars)

    section parser

    jump list

    delete logic

That’s where most of the plugin intelligence lives. And we can make it really clean and fast.

now sections.lua please

Alright, here’s a clean sections.lua implementation for your plugin.
This file will handle:

    detecting the correct comment prefix from commentstring

    building a 100-character section line

    creating a section

    listing sections

    jumping to a section

    deleting the current section

Using commentstring is the proper way because Neovim stores language-specific comment markers there (e.g. // %s, # %s, -- %s).
lua/sections/sections.lua

local M = {}

local WIDTH = 100


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
local function build_line(desc)
    local prefix = get_comment_prefix()

    local start = prefix .. " <" .. desc .. "> "
    local ending = " " .. prefix

    local dash_count = WIDTH - #start - #ending
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

    local line = build_line(desc)

    vim.api.nvim_put({ line }, "l", true, true)
end


-- detect section lines
local function is_section(line)
    return line:match("<.-%>")
end


-- collect sections
local function get_sections()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local sections = {}

    for i, line in ipairs(lines) do
        if is_section(line) then
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


-- delete section under cursor
function M.delete()
    local line_nr = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()

    if not is_section(line) then
        print("Not on a section line")
        return
    end

    vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, {})
end


return M

What this supports now

Commands you defined earlier will work:

:SectionCreate
:SectionCreate Rendering
:SectionJump
:SectionDelete

Example output (in C/C++):

// <Rendering Pipeline> ------------------------------------------------------- //

Example output (in Python):

# <Rendering Pipeline> ------------------------------------------------------- #

Next thing I strongly recommend

Right now the section detection is weak:

line:match("<.-%>")

That could match random code.

A better regex would be something like:

^%s*<comment> <%w+>

But since <comment> depends on language, we should generate the pattern dynamically.

That improvement will make the plugin robust enough for real use.

If you want, the next step I'd implement (and this makes the plugin feel really nice) is:

    section motions

    ]s  next section
    [s  previous section

    Telescope integration

    auto-update section width if edited

Those turn this from a small helper into a very slick navigation plugin.

create the robust search mechanism, also to identify the section line, we gave a plugin option to set the marker word, for me the marker word would be "S3C7I0N"  then the line would be " // <Description> [S3C7I0N] ----------------------  //"(the section line should enclose the section therefore there should be two lines persection one below and one above

Nice — adding a marker token + two boundary lines is exactly the right move. It makes section detection deterministic instead of heuristic.

Using a marker is robust because you can search for the exact pattern instead of guessing comment shapes or text. Since comment syntax varies across languages, Neovim plugins typically rely on the buffer’s commentstring option to obtain the correct comment prefix (e.g. // %s, # %s, etc.) rather than hardcoding comment characters.

So we’ll build detection around:

<comment> <Description> [MARKER] ----- <comment>

and each section is two identical lines (top + bottom).

Example:

// <Renderer> [S3C7I0N] -------------------------------------------------------- //
// code here
// code here
// <Renderer> [S3C7I0N] -------------------------------------------------------- //

Updated sections.lua (robust detection)

local M = {}

local config = {
    width = 100,
    marker = "S3C7I0N",
}

function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
end


-- ---------------------------------------------------------
-- comment helpers
-- ---------------------------------------------------------

local function get_comment_parts()
    local cs = vim.bo.commentstring

    if not cs or cs == "" then
        return "//", ""
    end

    local left, right = cs:match("^(.*)%%s(.*)$")

    left = (left or "//"):gsub("%s+$", "")
    right = (right or ""):gsub("^%s+", "")

    return left, right
end


-- ---------------------------------------------------------
-- build section line
-- ---------------------------------------------------------

local function build_line(desc)
    local left, right = get_comment_parts()

    local middle = " <" .. desc .. "> [" .. config.marker .. "] "

    local start = left .. middle
    local ending = " " .. left

    if right ~= "" then
        ending = " " .. right
    end

    local dash_count = config.width - #start - #ending
    if dash_count < 1 then dash_count = 1 end

    return start .. string.rep("-", dash_count) .. ending
end


-- ---------------------------------------------------------
-- section regex
-- ---------------------------------------------------------

local function section_pattern()
    local marker = vim.pesc(config.marker)
    return "%[" .. marker .. "%]"
end


local function is_section_line(line)
    return line:find(section_pattern()) ~= nil
end


-- ---------------------------------------------------------
-- create section
-- ---------------------------------------------------------

function M.create(desc)

    if not desc or desc == "" then
        desc = vim.fn.input("Section name: ")
        if desc == "" then return end
    end

    local line = build_line(desc)

    vim.api.nvim_put({
        line,
        "",
        line
    }, "l", true, true)
end


-- ---------------------------------------------------------
-- find sections
-- ---------------------------------------------------------

local function find_sections()

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local sections = {}

    local i = 1
    while i <= #lines do
        if is_section_line(lines[i]) then

            table.insert(sections, {
                start = i,
                text = lines[i]
            })

        end

        i = i + 1
    end

    return sections
end


-- ---------------------------------------------------------
-- jump
-- ---------------------------------------------------------

function M.jump()

    local sections = find_sections()

    if #sections == 0 then
        print("No sections found")
        return
    end

    local items = {}

    for _, s in ipairs(sections) do
        table.insert(items, s.text)
    end

    vim.ui.select(items, { prompt = "Jump to section" }, function(_, idx)

        if not idx then return end

        vim.api.nvim_win_set_cursor(0, { sections[idx].start, 0 })

    end)

end


-- ---------------------------------------------------------
-- delete section block
-- ---------------------------------------------------------

function M.delete()

    local line_nr = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    if not is_section_line(lines[line_nr]) then
        print("Not on a section boundary")
        return
    end

    -- find matching boundary
    local marker = section_pattern()

    local i = line_nr + 1
    while i <= #lines do

        if lines[i]:find(marker) then

            vim.api.nvim_buf_set_lines(
                0,
                line_nr - 1,
                i,
                false,
                {}
            )

            return
        end

        i = i + 1
    end

    print("Matching section boundary not found")

end


return M

Plugin config (marker option)

In your plugin setup:

require("sections").setup({
    marker = "S3C7I0N",
    width = 100
})

What this version guarantees

Robustness improvements:

✔ deterministic section detection
✔ independent of comment syntax
✔ safe deletion of full block
✔ customizable marker
✔ works with languages like:

# Python
-- Lua
// C++
<!-- HTML -->

Example result

# <Database Layer> [S3C7I0N] --------------------------------------------------- #
# code
# code
# <Database Layer> [S3C7I0N] --------------------------------------------------- #

💡 Next feature I strongly recommend adding (this is where it becomes a great plugin):

1️⃣ Section motions

]s  next section
[s  previous section

2️⃣ Section textobject

vis   select section
dis   delete section

3️⃣ Telescope section picker

4️⃣ Auto-fold sections

Those 4 things would make this plugin feel like a real structural navigation system, similar to code outlines but lighter.

If you want, I can also show a very clever trick that makes section jumps O(log n) instead of O(n) for huge files.

do I need to update the init.lua now, yes add the navigation and textobject features as well   only the keymaps should be <leader>ns and ,<leader>ps for next and previous respectively

Yep — you do need to update init.lua now because:

    We added plugin configuration (setup)

    We added navigation keymaps

    We added textobjects

A common Neovim plugin pattern is: setup() configures the plugin and registers commands/mappings.

Also, keymaps should be created with vim.keymap.set() which allows mapping Lua functions directly and attaching descriptions.
1. Updated lua/sections/init.lua

local M = {}

local config = {
    marker = "S3C7I0N",
    width = 100,
}

function M.setup(opts)

    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end

    require("sections.sections").setup(config)
    require("sections.commands").setup()

    local nav = require("sections.sections")

    -- navigation
    vim.keymap.set(
        "n",
        "<leader>ns",
        nav.next_section,
        { desc = "Next section" }
    )

    vim.keymap.set(
        "n",
        "<leader>ps",
        nav.prev_section,
        { desc = "Previous section" }
    )

    -- textobjects
    vim.keymap.set(
        { "o", "x" },
        "is",
        nav.textobj_inner,
        { desc = "Inside section" }
    )

    vim.keymap.set(
        { "o", "x" },
        "as",
        nav.textobj_around,
        { desc = "Around section" }
    )

end

return M

2. Add navigation + textobjects to sections.lua

Append these functions to the file.
Next section

function M.next_section()

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

    for i, l in ipairs(lines) do
        if is_section_line(l) then
            vim.api.nvim_win_set_cursor(0, { line + i, 0 })
            return
        end
    end

end

Previous section

function M.prev_section()

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)

    for i = #lines, 1, -1 do
        if is_section_line(lines[i]) then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end

end

3. Section range detection (used for textobjects)

Add this helper:

local function find_section_bounds()

    local cursor = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local start_line = nil
    local end_line = nil

    for i = cursor, 1, -1 do
        if is_section_line(lines[i]) then
            start_line = i
            break
        end
    end

    if not start_line then
        return nil
    end

    for i = start_line + 1, #lines do
        if is_section_line(lines[i]) then
            end_line = i
            break
        end
    end

    if not end_line then
        return nil
    end

    return start_line, end_line
end

4. Textobject: inner section

Select contents only.

function M.textobj_inner()

    local s, e = find_section_bounds()
    if not s then return end

    vim.fn.setpos("'<", {0, s + 1, 1, 0})
    vim.fn.setpos("'>", {0, e - 1, 1, 0})

    vim.cmd("normal! gv")

end

5. Textobject: around section

Select entire block including borders.

function M.textobj_around()

    local s, e = find_section_bounds()
    if not s then return end

    vim.fn.setpos("'<", {0, s, 1, 0})
    vim.fn.setpos("'>", {0, e, 1, 0})

    vim.cmd("normal! gv")

end

6. Final keybindings

Navigation:

<leader>ns   next section
<leader>ps   previous section

Textobjects:

vis   select inside section
vas   select around section
dis   delete section contents
das   delete section including borders

Example:

vas

selects

 // <Renderer> [S3C7I0N] ------------------ //
 code
 code
 // <Renderer> [S3C7I0N] ------------------ //

💡 One improvement I’d strongly recommend next (and most plugins miss this):

Right now section search is O(n).

We can make navigation O(log n) using a cached section index updated with BufWrite / TextChanged.
That makes the plugin instant even on 50k-line files.

If you want, I can show you the clean architecture used by high-performance Neovim plugins for that.

when loading the plugin  neovim throws the error the setup in init.lua is a nil value

That error almost always means require("sections") returned a table that does NOT contain setup. So when Neovim runs:

require("sections").setup()

Lua evaluates it as:

    local module = require("sections")

    module.setup()

If setup doesn't exist, Lua throws “attempt to call field 'setup' (a nil value)”.

So the issue is almost certainly one of these three things.
1. Check your directory layout (most common cause)

Your plugin folder must look exactly like this:

sections.nvim/
├── plugin/
│   └── sections.lua
└── lua/
    └── sections/
        ├── init.lua
        ├── commands.lua
        └── sections.lua

Important detail:

lua/sections/init.lua

must exist — otherwise:

require("sections")

returns nil or wrong module.
2. Verify lua/sections/init.lua

It must return the module table:

local M = {}

function M.setup(opts)
    require("sections.sections").setup(opts)
    require("sections.commands").setup()
end

return M

The critical line:

return M

If that is missing → setup becomes nil.
3. Check your plugin loader

plugin/sections.lua should be:

require("sections").setup()

Nothing else.

Remember: files inside plugin/ run automatically at startup.
4. Quick debugging trick

Run inside Neovim:

:lua print(vim.inspect(require("sections")))

You should see something like:

{
  setup = function: 0x....
}

If you see:

true

or

nil

then the module path is wrong.
5. Another common mistake

If your folder is named:

sections

instead of

sections.nvim

that’s fine — but the lua/sections folder must still exist.
6. Quick sanity test

Try running inside Neovim:

:lua require("sections")

If it errors:

module 'sections' not found

then Neovim cannot see the plugin on the runtimepath.

✅ Fastest fix:
Show me your exact directory tree (output of):

tree sections.nvim

or

ls -R

because with Neovim plugins 95% of errors are directory layout mistakes.

Once that’s fixed we can also add one more thing that will make your plugin feel professional:

    automatic section folding (super nice with your design).


how should the load code look in my config

There are two correct ways to load your plugin depending on how you installed it. I’ll show the recommended one for developing a plugin locally, and the manual packpath method.
1. If your plugin is installed as a package (recommended)

Directory:

~/.local/share/nvim/site/pack/dev/start/sections.nvim

Neovim automatically loads plugins in pack/*/start/* at startup.

So your config does not need to require the plugin manually.

Your config should only configure it:

require("sections").setup({
    marker = "S3C7I0N",
    width = 100
})

Example init.lua:

vim.g.mapleader = " "

require("sections").setup({
    marker = "S3C7I0N",
    width = 100
})

That's it.

Your plugin/sections.lua file will already run automatically.
2. If you're developing the plugin in a custom folder

Example:

~/dev/sections.nvim

Add it to the runtime path in your config.

vim.opt.rtp:prepend("~/dev/sections.nvim")

require("sections").setup({
    marker = "S3C7I0N",
    width = 100
})

This tells Neovim to treat that directory as a plugin.
3. If you use lazy.nvim

Add this to your plugin list:

{
    dir = "~/dev/sections.nvim",
    config = function()
        require("sections").setup({
            marker = "S3C7I0N",
            width = 100
        })
    end
}

4. Minimal working example

Your entire config could literally be:

vim.g.mapleader = " "

require("sections").setup({
    marker = "S3C7I0N",
    width = 100
})

5. Quick debugging command

Run in Neovim:

:lua print(vim.inspect(require("sections")))

Expected output:

{
  setup = function: ...
}

If you see:

true

or

nil

then your plugin is not on the runtimepath.

💡 One small but important thing about your plugin loader

Your plugin/sections.lua should NOT call require("sections").setup() automatically.

Neovim plugin best practice is:

    plugin/ → define commands/keymaps

    setup() → only called by the user config

So your plugin/sections.lua should look like:

require("sections.commands").setup()

and your config calls setup().

If you want, I can also show you a very nice plugin structure used by Telescope/Treesitter plugins that avoids a bunch of common problems (like the one you just hit). It will make your plugin architecture much cleaner.

this sections.lua doesn't contain any setup function "local M = {}

local WIDTH = 100


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
local function build_line(desc)
    local prefix = get_comment_prefix()

    local start = prefix .. " <" .. desc .. "> "
    local ending = " " .. prefix

    local dash_count = WIDTH - #start - #ending
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

    local line = build_line(desc)

    vim.api.nvim_put({ line }, "l", true, true)
end


-- detect section lines
local function is_section(line)
    return line:match("<.-%>")
end


-- collect sections
local function get_sections()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local sections = {}

    for i, line in ipairs(lines) do
        if is_section(line) then
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


-- delete section under cursor
function M.delete()
    local line_nr = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()

    if not is_section(line) then
        print("Not on a section line")
        return
    end

    vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, {})
end

function M.next_section()

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

    for i, l in ipairs(lines) do
        if is_section(l) then
            vim.api.nvim_win_set_cursor(0, { line + i, 0 })
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
        if is_section(lines[i]) then
            start_line = i
            break
        end
    end

    if not start_line then
        return nil
    end

    for i = start_line + 1, #lines do
        if is_section(lines[i]) then
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

    vim.fn.setpos("'<", {0, s + 1, 1, 0})
    vim.fn.setpos("'>", {0, e - 1, 1, 0})

    vim.cmd("normal! gv")

end

function M.textobj_around()

    local s, e = find_section_bounds()
    if not s then return end

    vim.fn.setpos("'<", {0, s, 1, 0})
    vim.fn.setpos("'>", {0, e, 1, 0})

    vim.cmd("normal! gv")

end



return M" it is required by the init.lua that you provided

You’re absolutely right to notice that — the sections.lua you pasted has no setup(), but the init.lua I gave earlier expects it to exist, which is why Neovim throws:

attempt to call field 'setup' (a nil value)

That’s simply a mismatch between the modules.

In Neovim plugins, a setup(opts) function is usually used to configure the plugin and store user options (like your marker and width) before other functions run.

So we just need to add a setup system and config table to sections.lua.
Fix: add configuration + setup()

Update the top of lua/sections/sections.lua like this.

local M = {}

local config = {
    width = 100,
    marker = "S3C7I0N",
}

function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend("force", config, opts)
    end
end

Then replace your constant:

local WIDTH = 100

with

local function WIDTH()
    return config.width
end

and change the line builder:

local dash_count = WIDTH() - #start - #ending

Improve section detection (use the marker)

Your current detection:

line:match("<.-%>")

is too weak.

Replace is_section() with:

local function is_section(line)
    local marker = "%[" .. vim.pesc(config.marker) .. "%]"
    return line:find(marker) ~= nil
end

Now the plugin only detects lines containing:

[S3C7I0N]

which is exactly what you wanted.
Your init.lua now works

local M = {}

function M.setup(opts)
    require("sections.sections").setup(opts)
    require("sections.commands").setup()
end

return M

User config:

require("sections").setup({
    marker = "S3C7I0N",
    width = 100,
})

Quick sanity check inside Neovim

Run:

:lua print(vim.inspect(require("sections")))

Expected:

{
  setup = function: ...
}

If you see that, the plugin entrypoint is correct.

💡 Small design tip for your plugin:

Right now navigation scans the whole buffer every time. That works but scales poorly.

A very nice improvement later is to maintain a section index cache using:

TextChanged
BufWritePost
BufReadPost

Then navigation becomes instant even in 100k-line files.

If you want, I can also show you the clean architecture used by Telescope/Treesitter plugins to structure plugins like this — it’ll make your codebase much easier to extend.

"function M.next_section()

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

    for i, l in ipairs(lines) do
        if is_section(l) then
            vim.api.nvim_win_set_cursor(0, { line + i, 0 })
            return
        end
    end

end" based on this create a prev_section func as well

Your next_section() scans forward from the cursor using nvim_buf_get_lines(). The reverse version just needs to:

    Get lines before the cursor

    Iterate backwards

    Jump when a section marker is found

(nvim_buf_get_lines(buf, start, end, ...) returns a range of lines from the buffer, using zero-based indexing, which is why your code uses line directly as the start index.)
prev_section implementation

function M.prev_section()

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)

    for i = #lines, 1, -1 do
        if is_section(lines[i]) then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end

end

How it works

    line → current cursor line

    nvim_buf_get_lines(0, 0, line-1, false)
    gets all lines before the cursor

    iterate backwards:

for i = #lines, 1, -1

    when a section marker is found → jump to that line

Your navigation pair now

function M.next_section()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, line, -1, false)

    for i, l in ipairs(lines) do
        if is_section(l) then
            vim.api.nvim_win_set_cursor(0, { line + i, 0 })
            return
        end
    end
end

function M.prev_section()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)

    for i = #lines, 1, -1 do
        if is_section(lines[i]) then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end
end

✅ These match your keymaps perfectly:

<leader>ns  -> next section
<leader>ps  -> previous section

If you want, I can also show a much nicer navigation trick using vim.fn.search() that:

    skips the current section

    is way faster

    avoids scanning the whole buffer in Lua

Most mature plugins use that approach.

what vim api function to do some action like go up go down with k and j some thing like vim.action() or something

There isn’t a vim.action() function. In Neovim Lua you typically do one of three things to trigger normal-mode actions like j, k, etc.
1. The simplest: run a normal command

vim.cmd("normal! j")

Example:

vim.cmd("normal! k")

This executes the exact normal-mode command.
normal! avoids user mappings interfering.

Example function:

function go_down()
    vim.cmd("normal! j")
end

2. Simulate keypresses (most flexible)

Use:

vim.api.nvim_feedkeys()

This simulates the user pressing keys like j, k, <Esc>, etc.

Example:

vim.api.nvim_feedkeys("j", "n", false)

Example function:

function go_up()
    vim.api.nvim_feedkeys("k", "n", false)
end

3. Direct cursor movement (fastest / API-level)

If you just want to move the cursor:

local row, col = unpack(vim.api.nvim_win_get_cursor(0))
vim.api.nvim_win_set_cursor(0, {row + 1, col})

Example:

function go_down()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_win_set_cursor(0, {row + 1, col})
end

Which one should you use?

For a plugin like yours, the best options are:
Use vim.cmd("normal!")

Best for executing Vim motions.

vim.cmd("normal! j")

Use the API

Best when you want precise cursor control.

vim.api.nvim_win_set_cursor(...)

Avoid feedkeys() unless you really need to simulate typing.
Example inside your plugin

For example, if you want to move below the section header:

vim.cmd("normal! j")

or

local r,c = unpack(vim.api.nvim_win_get_cursor(0))
vim.api.nvim_win_set_cursor(0, {r+1, c})

💡 Small Neovim plugin tip:
Most plugins prefer API cursor movement (nvim_win_set_cursor) instead of normal commands because:

    faster

    no mapping conflicts

    more predictable

If you want, I can also show you a very neat trick used by Telescope and Treesitter plugins to jump to lines using vim.fn.search(), which would make your section navigation much cleaner than manual scanning.

how to do esc in vim.cmd

To send Esc inside vim.cmd() you use the special key notation:

\<Esc>

Example:

vim.cmd("normal! iHello\<Esc>")

This means:

    enter insert mode (i)

    type Hello

    press Esc to return to normal mode

In Vimscript commands, special keys like Escape must be written as \<Esc> so the command parser interprets it correctly.
Example uses
Exit insert mode

vim.cmd("normal! \<Esc>")

Insert text then leave insert mode

vim.cmd("normal! iHello World\<Esc>")

Visual selection then escape

vim.cmd("normal! vj\<Esc>")

Tip (cleaner syntax)

Using Lua multiline strings avoids escaping:

vim.cmd([[normal! iHello<Esc>]])

But the safest version is still:

vim.cmd("normal! iHello\\<Esc>")

because Lua requires escaping the backslash.
For plugins (better approach)

For plugin code like yours, it’s usually better to avoid normal entirely and instead use the API:

vim.api.nvim_win_set_cursor(0, {line, col})

It’s:

    faster

    unaffected by mappings

    more predictable

If you want, I can also show a very useful helper most plugin authors add that lets you write:

normal("vj<Esc>")

instead of dealing with all the escaping — it makes Lua plugin code much nicer.

but that is an invalid escape according to lua

Yep — your instinct is correct. Lua complains because \ <something> inside a string must be a valid Lua escape sequence, and \< is not valid, so Lua throws:

invalid escape sequence

Lua only allows a limited set like \n, \t, \\, \", etc.

So this line breaks in Lua:

vim.cmd("normal! iHello\<Esc>")

because Lua tries to interpret \<.
Correct ways to write <Esc> in vim.cmd
1. Escape the backslash (most common)

You must escape the backslash for Lua:

vim.cmd("normal! iHello\\<Esc>")

Explanation:

Lua string     -> \\<Esc>
Actual string  -> \<Esc>
Vim receives   -> <Esc>

2. Use Lua long strings (cleaner)

Lua has raw strings with [[ ... ]] that do not process escapes.

vim.cmd([[normal! iHello<Esc>]])

This is usually the nicest solution.
3. Use vim.api.nvim_replace_termcodes (best for plugins)

local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
vim.api.nvim_feedkeys(esc, "n", false)

This converts <Esc> to the internal keycode Neovim expects.
What I recommend for your plugin

Since you’re writing a plugin, the cleanest pattern is:

vim.cmd([[normal! j<Esc>]])

or even better, avoid normal entirely and use the API:

local row, col = unpack(vim.api.nvim_win_get_cursor(0))
vim.api.nvim_win_set_cursor(0, {row + 1, col})

That avoids escaping problems entirely.

✅ Quick rule to remember
What you write	Lua sees
\<Esc>	❌ invalid
\\<Esc>	✔ correct
[[<Esc>]]	✔ best

If you want, I can also show a very useful helper most Neovim plugins add:

normal("ggVG")

which avoids all the escape madness when writing Lua plugins. It makes plugin code way cleaner.


