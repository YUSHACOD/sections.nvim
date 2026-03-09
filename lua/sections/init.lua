local M = {}

local config = {
    marker = "(section)",
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
        "]s",
        nav.next_section,
        { desc = "Next section" }
    )

    vim.keymap.set(
        "n",
        "[s",
        nav.prev_section,
        { desc = "Previous section" }
    )

    vim.keymap.set(
        "n",
        "<leader>es",
        nav.jump_end,
        { desc = "Jume to end of section" }
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
