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

    -- command-like helpers (optional keymaps)
    if config.keymaps and config.keymaps.create then
        vim.keymap.set(
            "n",
            config.keymaps.create,
            function()
                nav.create()
            end,
            { desc = "Create section" }
        )
    end

    if config.keymaps and config.keymaps.jump then
        vim.keymap.set(
            "n",
            config.keymaps.jump,
            function()
                nav.jump()
            end,
            { desc = "Jump to section" }
        )
    end

    if config.keymaps and config.keymaps.delete then
        vim.keymap.set(
            "n",
            config.keymaps.delete,
            function()
                nav.delete()
            end,
            { desc = "Delete section" }
        )
    end

    if config.keymaps and config.keymaps.telescope then
        vim.keymap.set(
            "n",
            config.keymaps.telescope,
            function()
                nav.telescope()
            end,
            { desc = "Sections Telescope picker" }
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
