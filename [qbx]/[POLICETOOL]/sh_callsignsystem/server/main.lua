lib.addCommand('lamcallsign', {
  help = 'Set a vehicle\'s callsign',
  params = {
    {
      name = 'target',
      type = 'playerId',
      help = 'Target player\'s server id',
      optional = true
    },
  },
  restricted = false
}, function(source, args, raw)
  TriggerClientEvent('nk_callsigns:client:openMenu', args.target or source)
end)
