---@type table<string, { enabled: boolean, type: 'client'|'server'|'both', priority: number }>
Components = {
  ["Main"] = {
    enabled = true,
    type = 'both', -- enable client side
    priority = 2, -- 1 : init on start | 2 : init on player loaded
  },
}