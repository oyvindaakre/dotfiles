return {
	"mfussenegger/nvim-dap",

	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = {
				"nvim-neotest/nvim-nio",
			},
		},
		{
			-- Need a json parser that accepts the vscode launch files
			"Joakker/lua-json5",
			run = "./install.sh",
		},
		"jedrzejboczar/nvim-dap-cortex-debug", -- An extension for nvim-dap providing integration with Marus/cortex-debug debug adapter.
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("dapui").setup()

		-- Debug keymap
		vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
		vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
		vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
		vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
		-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
		vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })
		vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>B", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Debug: Set Breakpoint" })
		vim.keymap.set("n", "<Leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
		vim.keymap.set("n", "<Leader>dt", dap.terminate, { desc = "Debug: Terminate " })
		vim.keymap.set("n", "<Leader>dq", function()
			dap.terminate()
			dapui.close()
		end, { desc = "[D]ebug: [Q]uit" })
		vim.keymap.set("n", "<Leader>db", ":!meson compile -C build<CR>", { desc = "[D]ebug [B]uild code" })

		-- Automatically open the different windows when starting DAP
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		-- Setup dapui
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

		-- Configure native GDB debug adapter
		dap.adapters.gdb = {
			type = "executable",
			command = "gdb",
			args = { "-i", "dap" },
		}

		-- MCU debugging
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

		-- NOTE: Setup launch configurations
		-- Try to find an .elf file in a 'build' directory
		-- If not found then prompt the user for the path
		local dirname = "build"
		local build_files = io.popen("ls " .. dirname)
		local elf_file = nil
		for name in build_files:lines() do
			if string.match(name, "%.elf$") then
				elf_file = dirname .. "/" .. name
			end
		end

		-- Add the launch configuration for these filetypes
		-- Essentially this means you can hit F5 to open the debug UI from a file of this type
		local filetypes = { "c", "cpp", "netrw", "h" }

		-- Target device to debug. Will be used as parameter to the debugger so extend at will
		local devices = { "STM32L462VE", "STM32G473VE", "STM32L4S5VI", "LPC55S69_M33_0" }

		-- Make the launch configurations
		for _, ft in pairs(filetypes) do
			dap.configurations[ft] = {}

			for _, dev in pairs(devices) do
				local launch_config = {
					name = dev,
					cwd = "${workspaceFolder}", -- Will be expanded to 'cwd' automatically
					device = dev,
					executable = elf_file or function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					request = "launch",
					runToEntryPoint = "main",
					servertype = "jlink",
					type = "cortex-debug",
				}
				table.insert(dap.configurations[ft], launch_config)
			end
		end
		-- print(vim.inspect(dap.configurations.c))
	end,
}
