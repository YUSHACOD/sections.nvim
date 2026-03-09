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
- **`SecJump`**: Fuzzy‑pick a section and jump to it.
- **`SecDelete`**: Delete the section boundary line under the cursor (current behaviour is preserved).

### Keymaps (defaults)

- **`]s`**: Jump to next section boundary.
- **`[s`**: Jump to previous section boundary.
- **`<leader>es`**: Jump from a section start to its end boundary.
- **`is`** (operator‑pending / visual): Inner section (between the two boundaries).
- **`as`** (operator‑pending / visual): Around section (including boundaries).

All keymaps can be overridden via `keymaps` in `setup`.

### Section format

The plugin relies on the buffer's `commentstring` and a textual marker.  
With the default marker `(section)` the boundaries look roughly like:

```c
// (section) _Title_ ------------------------------ //
//   body of the section
// (section) $Title$ ------------------------------ //
```

In HTML, the same section becomes:

```html
<!-- (section) _Title_ ---------------------------- -->
  body of the section
<!-- (section) $Title$ ---------------------------- -->
```

The marker text is escaped when building the detection patterns, so it is safe to change it to something more unique.

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
- **`textobjects`** (`boolean`): Enable `is` / `as` textobjects. Default: `true`.
- **`commands`** (`boolean`): Register `:SecCreate`, `:SecJump`, `:SecDelete`. Default: `true`.
- **`wrap_navigation`** (`boolean`): Reserved for future wrap‑around navigation; currently unused.

The internal helpers in `sections.config`, `sections.comment`, `sections.format`, and `sections.util` are considered private and may change, but the public behaviour described above is preserved.

