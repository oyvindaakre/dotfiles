return {
	"mfussenegger/nvim-dap", -- DAP client

	dependencies = {
		-- Creates a beautiful debugger UI
		"rcarriga/nvim-dap-ui",

		-- Required dependency for nvim-dap-ui
		"nvim-neotest/nvim-nio",
		"Joakker/lua-json5", -- Remember to run install script (not sure how to do that yet from here)

		-- Installs the debug adapters for you
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",

		-- Add your own debuggers here
		-- Personally prefer to use Mason to install Marus/cortex-debug". If installing from here then make sure to set 'extension_path' to where lazy installed cortex-debug
		"jedrzejboczar/nvim-dap-cortex-debug", -- An extension for nvim-dap providing integration with Marus/cortex-debug debug adapter.
	},
	config = function()
		local dap = require("dap")
		dap.set_log_level("DEBUG")
		-- Set up and register with nvim-dap
		require("dap-cortex-debug").setup({
			debug = false, -- log debug messages
			-- path to cortex-debug extension, supports vim.fn.glob
			-- by default tries to guess: mason.nvim or VSCode extensions
			extension_path = nil,
			lib_extension = nil, -- shared libraries extension, tries auto-detecting, e.g. 'so' on unix
			node_path = "node", -- path to node.js executable
			dapui_rtt = true, -- register nvim-dap-ui RTT element
			-- make :DapLoadLaunchJSON register cortex-debug for C/C++, set false to disable
			dap_vscode_filetypes = { "c", "cpp", "netrw", "h" }, -- Added "netrw" so that you can get to the debugger menu from most places (i.e. not having to be in a c/h file)
		})

		require("dap.ext.vscode").json_decode = require("json5").parse
		-- Hack that replaces '${workspaceRoot}' in the launch.json files with cwd so that the elf files are found by the debugger
		-- Note that this will only work when launching nvim from the root directory of the project, so it's brittle
		require("dap.ext.vscode").load_launchjs() -- load .vsocde/launch.json

		local c_table = dap.configurations.c
		if c_table ~= nil then
			for _, v in pairs(c_table) do
				v["cwd"] = vim.fn.getcwd() -- replaces ${workspaceRoot} with cwd
			end

			dap.configurations.c = c_table -- write back configuration to dap
		end

		-- Debugger keymap
		vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
		vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
		vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
		vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
		vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>B", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Debug: Set Breakpoint" })

		-- Dap UI setup
		-- For more information, see |:help nvim-dap-ui|
		local dapui = require("dapui")
		dapui.setup({
			-- Set icons to characters that are more likely to work in every terminal.
			--    Feel free to remove or use ones that you like more! :)
			--    Don't feel like these are good choices.
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
		vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })

		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close
		-- config ends here
	end,
}
