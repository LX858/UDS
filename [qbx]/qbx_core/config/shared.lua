return {
    serverName = 'UNDERSTAR',
    defaultSpawn = vec4(251.1, -1012.05, 29.27, 74.36),
    notifyPosition = 'right', -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
    ---@type { name: string, amount: integer, metadata: fun(source: number): table }[]
    starterItems = { -- Character starting items
        { name = 'phone', amount = 1 },
        { name = 'banhmi', amount = 20 },
        { name = 'chieungu_newbie', amount = 10 },
        { name = 'nuocsuoi', amount = 20 },
        { name = 'balonewbie', amount = 1 },
        -- { name = 'id_card', amount = 1, metadata = function(source)
        --         assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
        --         return exports.qbx_idcard:GetMetaLicense(source, {'id_card'})
        --     end
        -- },
        -- { name = 'driver_license', amount = 1, metadata = function(source)
        --         assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
        --         return exports.qbx_idcard:GetMetaLicense(source, {'driver_license'})
        --     end
        -- },
    }
}
