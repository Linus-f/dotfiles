return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ruff = {
        on_attach = function(client)
          -- Disable LSP formatting so conform.nvim can take over
          client.server_capabilities.documentFormattingProvider = false
        end,
      },
    },
  },
}
