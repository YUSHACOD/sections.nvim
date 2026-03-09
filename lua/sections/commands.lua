local M = {}


function M.setup()
	local sec = require("sections.sections")

	vim.api.nvim_create_user_command(
		"SecCreate",
		function(opts)
			sec.create(opts.args)
		end,
		{
			nargs = "?",
			desc = "Create a new section"
		}
	)

	vim.api.nvim_create_user_command(
		"SecJump",
		function()
			sec.jump()
		end,
		{
			desc = "Jump to a section"
		}
	)

	vim.api.nvim_create_user_command(
		"SecDelete",
		function()
			sec.delete()
		end,
		{
			desc = "Delete the section under cursor"
		}
	)
end

return M
