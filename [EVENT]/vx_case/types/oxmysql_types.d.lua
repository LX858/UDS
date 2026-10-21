---@meta
-- oxmysql_types.d.lua  ·  Pure typings for OxMySQL (no runtime code)
-- https://github.com/overextended/oxmysql

--══════════════════════════════════════════════
--  ALIASES & CẤU TRÚC CƠ BẢN
--══════════════════════════════════════════════
---@alias SqlParameters table|nil        -- { 'val', 123 } | { id = 1 } | nil
---@alias Row           table                    -- 1 hàng dữ liệu: { col = value, ... }
---@alias Rows          Row[]                    -- nhiều hàng
---@class MySQLInfo                               -- Kết quả khi DML qua query()
---@field affectedRows integer
---@field changedRows  integer
---@field insertId     integer
---@field warnings     integer

--══════════════════════════════════════════════
--  “CALLABLE‑WITH‑AWAIT” – DÙNG @class : fun
--══════════════════════════════════════════════
---@generic R
---@class OxMySQLExec <R>
---@diagnostic disable-next-line: undefined-doc-name
---@field await fun(sql:string, params?:SqlParameters):R|nil   -- Phiên bản await (đồng bộ)
--══════════════════════════════════════════════
--  TRANSACTION TYPE
--══════════════════════════════════════════════
---@alias TransactionQuery fun(sql:string, params?:SqlParameters):any
---@alias TransactionFunc  fun(query:TransactionQuery):boolean|nil

---@diagnostic disable-next-line: undefined-doc-class
---@class OxMySQLTransaction : fun(fn:TransactionFunc, cb?:fun(success:boolean)):void
---@field await fun(fn:TransactionFunc):boolean    -- true = commit | false = rollback

--══════════════════════════════════════════════
--  BẢNG MODULE CHÍNH MySQL
--══════════════════════════════════════════════
---@class OxMySQL
---@field query       OxMySQLExec<Rows|MySQLInfo>  -- SELECT → Rows | DML → MySQLInfo
---@field single      OxMySQLExec<Row|nil>         -- Hàng đầu tiên (hoặc nil)
---@field scalar      OxMySQLExec<any|nil>         -- Giá trị đơn (cột 1, hàng 1)
---@field insert      OxMySQLExec<integer|nil>     -- insertId
---@field update      OxMySQLExec<integer>         -- affectedRows
---@field prepare     OxMySQLExec<any>             -- PREPARE/EXECUTE
---@field transaction OxMySQLTransaction
---@field escape fun(value:any):string
---@field escape_identifier fun(ident:string):string
MySQL = MySQL ---@type OxMySQL
