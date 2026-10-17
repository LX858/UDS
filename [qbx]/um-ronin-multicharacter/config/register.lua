
---@return table<string, any>
return {
    -- first and last name settings
    name = {
        minLength = 2,
        maxLength = 100,
    },

    dob = {
        -- DD-MM-YYYY, example: 31-12-2010
        -- YYYY-MM-DD, example: 2010-12-31
        -- MM-DD-YYYY, example: 12-31-2010
        format = 'DD-MM-YYYY',
        min = 1950,
        max = 2010
    },

    height = false, -- Enable/Disable height selection

    backstory = {
        enable = true,  -- Enable/Disable backstory selection (recommended true)
        minLength = 10, -- Minimum length of backstory
        maxLength = 300 -- Maximum length of backstory
    },

    nationalities = {
        'Vietnam',
    },

}
