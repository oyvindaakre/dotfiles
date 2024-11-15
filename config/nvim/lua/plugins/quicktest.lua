return {
  "quolpr/quicktest.nvim",
  config = function()
    local qt = require("quicktest")

    qt.setup({
      -- Choose your adapter, here all supported adapters are listed
      adapters = {
        require("quicktest.adapters.golang"),
        require("quicktest.adapters.vitest"),
        require("quicktest.adapters.criterion")({
          builddir = function(bufnr)
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            local builddir
            if string.find(bufname, "quicktest.nvim") ~= nil then
              builddir = "tests/support/criterion/build"
            elseif string.find(bufname, "dtools.nvim") ~= nil then
              builddir = "tests/build"
            else
              builddir = "build-utest"
            end
            print("bufnr: " .. tostring(bufnr))
            print("bufname: " .. bufname)
            print("using builddir: " .. builddir)
            return builddir
          end,
        }),
      },
      default_win_mode = "popup",
    })
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "m00qek/baleia.nvim",
  },
  keys = {
    {
      "<leader>tr",
      function()
        local qt = require("quicktest")
        -- current_win_mode return currently opened panel, split or popup
        qt.run_line()
        -- You can force open split or popup like this:
        -- qt().run_current('split')
        -- qt().run_current('popup')
      end,
      desc = "[T]est [R]un",
    },
    {
      "<leader>tR",
      function()
        local qt = require("quicktest")

        qt.run_file()
      end,
      desc = "[T]est [R]un file",
    },
    {
      "<leader>tp",
      function()
        local qt = require("quicktest")

        qt.run_previous()
      end,
      desc = "[T]est Run [P]revious",
    },
    {
      "<leader>tt",
      function()
        local qt = require("quicktest")

        qt.toggle_win("popup")
      end,
      desc = "[T]est [T]oggle popup window",
    },
    {
      "<leader>ts",
      function()
        local qt = require("quicktest")

        qt.toggle_win("split")
      end,
      desc = "[T]est Toggle [S]plit window",
    },
    {
      "<leader>ta",
      function()
        local qt = require("quicktest")
        qt.run_all()
      end,
      desc = "[T]est Run [A]ll",
    },
  },
}
