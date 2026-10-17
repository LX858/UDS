
Resmon     = {}
Resmon.Lib = {}

-- ----------------------------------------------------------------
-- 2.  Resmon.Lib._deepCopy(value)
--     Recursively deep-copies any value.
--     - Tables are cloned key-by-key (keys and values are also deep-copied).
--     - The metatable of the source table is deep-copied and applied to the clone.
--     - Non-table values are returned as-is.
-- ----------------------------------------------------------------
function Resmon.Lib._deepCopy(value)
    if type(value) == "table" then
        local copy = {}

        -- Copy every key-value pair recursively
        for key, val in next, value, nil do
            copy[Resmon.Lib._deepCopy(key)] = Resmon.Lib._deepCopy(val)
        end

        -- Also deep-copy and apply the original metatable
        setmetatable(copy, Resmon.Lib._deepCopy(getmetatable(value)))

        return copy
    else
        -- Primitive (number, string, boolean, function, etc.) – return directly
        return value
    end
end

-- ----------------------------------------------------------------
-- 3.  Resmon.Lib.Contains(tbl, searchValue)
--     Returns true if `searchValue` exists as a VALUE inside `tbl`.
--     Returns true (as "empty = contains nothing / always true") when
--     `tbl` is nil/falsy.
-- ----------------------------------------------------------------
function Resmon.Lib.Contains(tbl, searchValue)
    -- Guard: treat a nil/empty table as "always contains" (returns true)
    if not tbl then
        return true
    end

    for _, val in pairs(tbl) do
        if val == searchValue then
            return true
        end
    end

    return false
end

-- ----------------------------------------------------------------
-- 4.  Get0Resmon()
--     Simple getter that returns the global Resmon object.
--     Exported so other resources can retrieve the core object.
-- ----------------------------------------------------------------
function Get0Resmon()
    return Resmon
end

-- ----------------------------------------------------------------
-- 5.  Exports
--     Expose two export functions for other FiveM resources:
--       • exports.GetCoreObject()  → returns the Resmon table
--       • exports.Framework()      → returns Config.Framework string
-- ----------------------------------------------------------------

-- Export: retrieve the core Resmon object
exports("GetCoreObject", Get0Resmon)

-- Export: retrieve the configured framework name (e.g. "ESX", "QBCore")
exports("Framework", function()
    return Config.Framework
end)
