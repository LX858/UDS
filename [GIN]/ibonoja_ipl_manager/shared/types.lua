---@meta

---@class MapOptionPropset
---@field milo string
---@field coords vector3
---@field pattern string

---@class MapOptionValue
---@field label string
---@field value? { id: number|string, color?: number }
---@field description?: string

---@class MapOptionYmap
---@field name? string
---@field pattern? string
---@field customYmaps? table[]

---@class MapOption
---@field type "checkbox" | "scroll"
---@field label string
---@field icon? string
---@field statebag string
---@field configName string
---@field idReference?: string
---@field colorReference?: string
---@field propset?: MapOptionPropset
---@field ymap?: MapOptionYmap
---@field values?: MapOptionValue[]
---@field checked?: number
---@field defaultIndex?: number
---@field description?: string

---@class MapConfigMenu
---@field id string
---@field title string
---@field options MapOption[]

---@class MapConfig
---@field ResourceMapName string | string[]
---@field ConfigName string
---@field Menu MapConfigMenu
