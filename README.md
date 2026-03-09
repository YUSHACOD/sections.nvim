## sections.nvim

A tiny Neovim plugin that creates visual "sections" in your files using language‑aware comments.  
Sections are delimited by two boundary lines and can be created, jumped to, and selected with motions / textobjects.

### Features

- **Language‑aware comments**: Uses `commentstring`, so it works in Lua, Python, C/C++, HTML (`<!-- -->`), etc.
- **Fixed width lines**: Section boundaries are padded with `-` so the total width stays constant.
- **Sections as blocks**: Each section has a begin and end boundary line with a marker (by default `(section)`).
- **Navigation**: Jump to next/previous section or pick a section from a list.
- **Textobjects**: Operate on the inside of a section or the whole section (including boundaries).

### Installation

Example with `lazy.nvim` while developing locally:

```lua
{
  dir = "~/dev/sections.nvim",
  config = function()
    require("sections").setup({
      -- all options are optional; these are the defaults
      marker = "(section)",
      width = 100,
      keymaps = {
        next = "]s",
        prev = "[s",
        ["end"] = "<leader>es",
        create = "<leader>sc",
        jump = "<leader>sj",
        delete = "<leader>sd",
        telescope = "<leader>ss",
      },
      textobjects = true,
      commands = true,
      wrap_navigation = false,
    })
  end,
}
```

If you install as a regular package:

```lua
vim.g.mapleader = " "

require("sections").setup({
  marker = "(section)",
  width = 100,
})
```

### Commands

- **`SecCreate [name]`**: Create a new section. With no argument, prompts for the name.
- **`SecJump`**: Fuzzy‑pick a section using `vim.ui.select` and jump to it (no dependencies).
- **`SecDelete`**: Delete the section under the cursor (full block, including boundaries).
- **`SecTelescope`**: Open a Telescope picker of all sections and jump to the selected one (requires `nvim-telescope/telescope.nvim`).

### Keymaps (defaults)

- **`]s`**: Jump to next section boundary.
- **`[s`**: Jump to previous section boundary.
- **`<leader>es`**: Jump from a section start to its end boundary.
- **`is`** (operator‑pending / visual): Inner section (between the two boundaries).
- **`as`** (operator‑pending / visual): Around section (including boundaries).

All keymaps can be overridden via `keymaps` in `setup`.

### Section format

The plugin relies on the buffer's `commentstring` to build section boundaries.
With a C-style line comment (`// %s`) and the default marker `(section)` the
boundaries look roughly like:

```c
//  Title : -------------------- (section) //
//   body of the section
//  (section) -------------------- : Title //
```

In HTML, the same section becomes:

```html
<!--  Title : ------------------ (section) -->
  body of the section
<!--  (section) ------------------ : Title -->
```

### HTML and block comment behaviour

- For **line comments** (`// %s`, `# %s`, `-- %s`), the prefix is mirrored on both sides: `// ... //`, `# ... #`, etc.
- For **block comments** (`<!-- %s -->`, `/* %s */`), the code uses the leading part for the left side and the trailing part for the right side: `<!-- ... -->`, `/* ... */`.
- The plugin uses `strdisplaywidth` to compute padding, so multi‑byte / wide characters in section titles will still produce visually aligned lines.

### Configuration reference

`require("sections").setup(opts)` accepts:

- **`marker`** (`string`): Text marker embedded in boundary lines. Default: `(section)`.
- **`width`** (`number`): Target visual width of the full boundary line. Values \< 20 are clamped to the default.
- **`keymaps`** (`table`):
  - `next` (`string`): Mapping for "next section". Default: `]s`.
  - `prev` (`string`): Mapping for "previous section". Default: `[s`.
  - `end` (`string`): Mapping for "jump to section end". Default: `<leader>es`.
  - `create` (`string`): Mapping for "create section" (`SecCreate` behaviour). Default: `<leader>sc`.
  - `jump` (`string`): Mapping for "jump to section" (`SecJump` behaviour). Default: `<leader>sj`.
  - `delete` (`string`): Mapping for "delete section" (`SecDelete` behaviour). Default: `<leader>sd`.
  - `telescope` (`string`): Mapping for `SecTelescope`. Default: `<leader>ss`.
- **`textobjects`** (`boolean`): Enable `is` / `as` textobjects. Default: `true`.
- **`commands`** (`boolean`): Register `:SecCreate`, `:SecJump`, `:SecDelete`. Default: `true`.
- **`wrap_navigation`** (`boolean`): Reserved for future wrap‑around navigation; currently unused.
- **`telescope_theme`** (`string|nil`): Name of Telescope theme to use for `SecTelescope` (e.g. `"dropdown"`, `"ivy"`). Default: `"dropdown"`. Set to `nil` to use raw Telescope layout options.

### Telescope integration

If you use Telescope, you can drive sections through a picker:

- **Command**: `:SecTelescope` (registered when `commands = true`).
- **Behaviour**: Lists all section starts in the current buffer; pressing `<CR>` jumps to the chosen section.

Minimal example mapping:

```lua
vim.keymap.set("n", "<leader>ss", "<cmd>SecTelescope<CR>", { desc = "Sections picker" })
```

The internal helpers in `sections.config`, `sections.comment`, `sections.format`, and `sections.util` are considered private and may change, but the public behaviour described above is preserved.

