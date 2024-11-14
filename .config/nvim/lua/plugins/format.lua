return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- PHP
        php = { "pint" },
        -- Terraform (OpenTofu)
        terraform = { "tofu_fmt" },
        tf = { "tofu_fmt" },
        ["terraform-vars"] = { "tofu_fmt" },
      },
    },
  },
}
