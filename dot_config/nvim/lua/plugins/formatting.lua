return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        black = {
          -- Explicitly prepend the argument to whatever else is there
          prepend_args = { "--line-length", "120" },
        },
      },
    },
  },
}
