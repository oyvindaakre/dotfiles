return {
  "Darazaki/indent-o-matic", -- Detect tabstop and shiftwidth automatically
  config = function()
    require("indent-o-matic").setup({
      -- Global settings (optional, used as fallback)
      max_lines = 2048,
      standard_widths = { 2, 4 },

      filetype_c = {
        standard_widths = { 4 },
      },

      -- Only detect 4 spaces and tabs for Rust files
      filetype_lua = {
        standard_widths = { 2 },
      },

      -- Don't detect 8 spaces indentations inside files without a filetype
      filetype_ = {
        standard_widths = { 2, 4 },
      },
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "c",
      callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 8 -- recommended to be different than shiftwidth to be able to detect actual tab characters
        vim.opt_local.expandtab = true
      end,
    })
    -- vim.cmd("autocmd! indent_o_matic")
  end,
}
