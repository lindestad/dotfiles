return {
  {
    "jake-stewart/multicursor.nvim",
    event = "BufReadPost",
    config = function()
      local mc = require("multicursor-nvim")

      mc.setup()

      -- Add cursor at next/prev search match. Keep pressing to accumulate.
      vim.keymap.set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Cursor at next match" })
      vim.keymap.set({ "n", "x" }, "<C-p>", function() mc.matchAddCursor(-1) end, { desc = "Cursor at prev match" })

      -- Skip the next match without adding a cursor (like helix's `s` skip).
      vim.keymap.set({ "n", "x" }, "<C-x>", function() mc.matchSkipCursor(1) end, { desc = "Skip next match" })

      -- Add cursors to every match in the file in one shot.
      vim.keymap.set({ "n", "x" }, "<C-a>", function() mc.matchAllAddCursors() end, { desc = "Cursor at all matches" })

      -- Add cursors above/below the current line.
      vim.keymap.set({ "n", "x" }, "<M-up>", function() mc.lineAddCursor(-1) end, { desc = "Cursor line above" })
      vim.keymap.set({ "n", "x" }, "<M-down>", function() mc.lineAddCursor(1) end, { desc = "Cursor line below" })
      vim.keymap.set({ "n", "x" }, "<C-k>", function() mc.lineAddCursor(-1) end, { desc = "Cursor line above" })
      vim.keymap.set({ "n", "x" }, "<C-j>", function() mc.lineAddCursor(1) end, { desc = "Cursor line below" })

      -- Within a visual selection: add cursors to lines, or match by regex.
      vim.keymap.set("x", "I", function() mc.insertVisual() end, { desc = "Cursor at start of each line" })
      vim.keymap.set("x", "A", function() mc.appendVisual() end, { desc = "Cursor at end of each line" })
      vim.keymap.set("x", "M", function() mc.matchCursors() end, { desc = "Cursor at regex matches in selection" })

      -- Escape clears all extra cursors.
      vim.keymap.set("n", "<Esc>", function()
        if not mc.hasCursors() then
          return "<Esc>"
        end
        mc.clearCursors()
      end, { expr = true, desc = "Clear cursors / Escape" })

      -- Highlight groups to make cursors visible.
      vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
      vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
      vim.api.nvim_set_hl(0, "MultiCursorMatchPreview", { link = "Search" })
      vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
      vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    end,
  },
}
