return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")

    harpoon:setup()

    vim.keymap.set("n", "<leader>a", function()
      harpoon:list():add()
    end, { desc = "Add to Harpoon list" })
    vim.keymap.set("n", "<C-s>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    -- vim.keymap.set("n", "<C-h>", function()
    -- 	harpoon:list():select(1)
    -- end)
    -- vim.keymap.set("n", "<C-j>", function()
    -- 	harpoon:list():select(2)
    -- end)
    -- vim.keymap.set("n", "<C-k>", function()
    -- 	harpoon:list():select(3)
    -- end)
    -- vim.keymap.set("n", "<C-l>", function()
    -- 	harpoon:list():select(4)
    -- end)

    -- Toggle previous & next buffers stored within Harpoon list
    -- vim.keymap.set("n", "<C-S-P>", function()
    -- 	harpoon:list():prev()
    -- end)
    -- vim.keymap.set("n", "<C-S-N>", function()
    -- 	harpoon:list():next()
    -- end)

    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():clear()
      harpoon:list():add()
    end, { desc = "Clear the Harpoon list AND add to list" })

    vim.keymap.set("n", "<leader>hr", function()
      harpoon:list():remove()
    end, { desc = "Remove current buffer from the Harpoon list" })
  end,
}
