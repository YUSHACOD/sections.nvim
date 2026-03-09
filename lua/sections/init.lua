local M = {}

local config_mod = require("sections.config")

local config = config_mod.defaults

function M.setup(opts)

    if opts then
        config = config_mod.normalize(opts)
    else
        config = config_mod.normalize(config)
    end

    require("sections.sections").setup(config)
    if config.commands then
        require("sections.commands").setup()
    end

    local nav = require("sections.sections")

    -- navigation
    if config.keymaps and config.keymaps.next then
        vim.keymap.set(
            "n",
            config.keymaps.next,
            nav.next_section,
            { desc = "Next section" }
        )
    end

    if config.keymaps and config.keymaps.prev then
        vim.keymap.set(
            "n",
            config.keymaps.prev,
            nav.prev_section,
            { desc = "Previous section" }
        )
    end

    if config.keymaps and config.keymaps["end"] then
        vim.keymap.set(
            "n",
            config.keymaps["end"],
            nav.jump_end,
            { desc = "Jump to end of section" }
        )
    end

    -- textobjects
    if config.textobjects then
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

end

return M
