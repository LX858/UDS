return {

    -- --- Expiry cron ---------------------------------------------------------
    -- How often to check for and remove expired props.
    -- Uses standard cron syntax.
    -- Examples: '*/5 * * * *' = every 5 minutes, '*/1 * * * *' = every minute
    expiryCron = '*/5 * * * *',

    -- --- Permission levels ----------------------------------------------------
    -- Levels are cumulative - each level includes all levels below it.
    --   1 (toggleGroups) – enable / disable prop groups
    --   2 (manage)       – add, move and delete props; view the map
    --   3 (playerAccess) – view and edit the player access list
    ace = {
        [1] = 'mod',
        [2] = 'mod',
        [3] = 'mod',
    },

    command = 'quanlyprops'
}
