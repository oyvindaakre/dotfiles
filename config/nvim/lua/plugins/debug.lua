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
    "theHamsta/nvim-dap-virtual-text",
    "oyvindaakre/dtools.nvim",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    local dtools = require("dtools")({
      builddir = function(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local builddir
        if string.find(bufname, "quicktest.nvim") ~= nil then
          builddir = "tests/support/criterion/build"
        elseif string.find(bufname, "dtools.nvim") ~= nil then
          builddir = "tests/build"
        elseif string.find(bufname, "test_") ~= nil then
          builddir = "build-utest"
        else
          builddir = "build"
        end
        return builddir
      end,
    })

    local header = require("dtools.header")

    require("dapui").setup()
    require("nvim-dap-virtual-text").setup()

    -- Add the launch configuration for these filetypes
    -- Essentially this means you can hit F5 to open the debug UI from a file of this type
    local debug_filetypes = { "c", "cpp", "netrw", "h" }

    -- Debug keymap
    vim.keymap.set("n", "<leader>dt", dtools.debug_test, { desc = "Debug: Test" })
    vim.keymap.set("n", "<F3>", dap.step_into, { desc = "Debug: Step Into" })
    vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
    vim.keymap.set("n", "<F4>", dap.step_out, { desc = "Debug: Step Out" })
    vim.keymap.set("n", "<F1>", dap.continue, { desc = "Debug: Start/Continue" })
    vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })
    vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
    vim.keymap.set("n", "<leader>B", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Debug: Set Breakpoint" })
    vim.keymap.set("n", "<Leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
    vim.keymap.set("n", "<Leader>dq", function()
      dap.terminate()
      dapui.close()
    end, { desc = "[D]ebug: [Q]uit" })
    vim.keymap.set("n", "<Leader>db", function()
      vim.cmd("!ninja -C " .. dtools.get_builddir())
    end, { desc = "[D]ebug [B]uild code" })
    vim.keymap.set("n", "<leader>hg", header.insert_header_guard, { desc = "[H]eader [G]uard" })

    -- Used to select a launch configuration to keep so that the next time you
    -- start debugging nvim automatically uses this configuration instead of asking
    -- you to select from a list. Usually I want to debug the same target every time
    -- and dont want to spend time selecting it from a list over and over.
    vim.keymap.set("n", "<Leader>dC", function()
      local opts = {}
      for _, v in pairs(dap.configurations.c) do
        table.insert(opts, v["name"])
      end

      vim.ui.select(opts, { prompt = "Select configuration to keep" }, function(choice)
        if choice == nil then
          return
        end
        print("Keeping configuration " .. choice)

        local temp = nil
        for _, v in pairs(dap.configurations.c) do
          if v["name"] == choice then
            temp = v
            break
          end
        end
        for _, v in pairs(debug_filetypes) do
          dap.configurations[v] = { temp }
        end
      end)
    end, { desc = "[D]ebug: Select [C]onfiguration to keep" })

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
      dap_vscode_filetypes = debug_filetypes,
    })

    --NOTE: Utility function to find executables for debugging
    local function find_exe(dirname, filename)
      local prompt = "find " .. dirname .. "/ -maxdepth 1"
      if filename == nil or filename == "" then
        prompt = prompt .. " -executable -type f"
      else
        prompt = prompt .. " -name '" .. filename .. "'"
      end

      local build_files = io.popen(prompt)
      if build_files == nil then
        return nil
      end

      for name in build_files:lines() do
        return name
      end

      return nil
    end

    -- NOTE: Setup launch configurations
    -- Try to find an .elf file in a 'build' directory
    -- If not found then prompt the user for the path
    local elf_file = nil
      or find_exe("build", "main_debugger.elf")
      or find_exe("build", "main.elf")
      or find_exe("build/zephyr", "zephyr.elf")
    -- Target devices to debug.
    -- The device name will be passed as a parameter to the debug probe.
    -- NOTE: See also <Leader>dC key to select configuration to keep for this nvim session
    local devices = {
      { device = "STM32L462VE", descr = "com, power" },
      { device = "STM32G473VE", descr = "power" },
      { device = "STM32L4S5VI", descr = "power" },
      { device = "LPC55S69_M33_0", descr = "power" },
    }

    -- Make the launch configurations
    local load_launch_configs = function()
      for _, ft in pairs(debug_filetypes) do
        dap.configurations[ft] = {}
        for _, dev in pairs(devices) do
          -- Launch configuration
          local launch = {
            name = dev["device"] .. " (" .. dev["descr"] .. ") [Launch]",
            cwd = "${workspaceFolder}", -- Will be expanded to 'cwd' automatically
            device = dev["device"],
            executable = elf_file or function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            servertype = "jlink",
            type = "cortex-debug",
            request = "launch",
            runToEntryPoint = "main",
          }

          -- Attach configurations
          local attach = {
            name = dev["device"] .. " (" .. dev["descr"] .. ") [Attach]",
            cwd = "${workspaceFolder}", -- Will be expanded to 'cwd' automatically
            device = dev["device"],
            executable = elf_file or function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            servertype = "jlink",
            type = "cortex-debug",
            request = "attach",
          }
          table.insert(dap.configurations[ft], launch)
          table.insert(dap.configurations[ft], attach)
        end

        -- Add a configuration for debugging unit tests
        local debug_unit_test = {
          name = "Debug unit test",
          type = "gdb",
          request = "attach",
          program = function()
            local exe, err = dtools.start_debug_server()
            if err ~= nil then
              print(err)
              return nil
            end
            return exe
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = true,
          target = "localhost:1234",
        }
        table.insert(dap.configurations[ft], debug_unit_test)

        -- Add a configuration for debugging native apps
        local debug_native_app = {
          name = "Debug native",
          type = "gdb",
          request = "launch",
          program = find_exe("build") or function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = true,
        }
        table.insert(dap.configurations[ft], debug_native_app)
      end
      -- print(vim.inspect(dap.configurations.c))
    end

    -- Load them by defualt
    load_launch_configs()

    -- Force reload of all configurations. Useful if removed by <Leader>dC
    vim.keymap.set("n", "<Leader>dL", load_launch_configs, { desc = "[D]ebug [L]oad launch configurations" })
  end,
}
