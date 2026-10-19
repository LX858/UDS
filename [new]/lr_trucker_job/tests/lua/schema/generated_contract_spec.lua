local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertNil(value, message)
  if value ~= nil then error(message or "expected nil") end
end

LR = {}
dofile("shared/core/lr.lua")
dofile("shared/core/schema.lua")
dofile("client/generated/contracts.lua")
dofile("client/generated/contracts/main.lua")
dofile("client/generated/contracts/trucker.lua")

local mainContract = LR.Generated.Contracts.main
assertTrue(mainContract.nui.state.game.validate({ playerName = "Ada", playerId = "42" }))
local truckerClientContract = LR.Generated.Contracts.trucker
assertTrue(truckerClientContract.nui.state.visibility.validate({ visible = true }))
assertNil(truckerClientContract.nui.state.snapshot.owner, "compiled generated state retained an owner")
assertTrue(truckerClientContract.nui.rpc.toClient.close.request({}))
assertNil(truckerClientContract.net.rpc.clientToServer.kick, "removed team RPC remained public")
assertNil(truckerClientContract.net.events.serverToClient.invitation, "removed team event remained public")
assertTrue(truckerClientContract.net.rpc.clientToServer.packageAction.mutating)
assertNil(truckerClientContract.exports.server, "client contract leaked server exports")

LR.Generated.Contracts = {}
dofile("server/generated/contracts.lua")
dofile("server/generated/contracts/trucker.lua")

local truckerServerContract = LR.Generated.Contracts.trucker
assertTrue(truckerServerContract.net.rpc.clientToServer.advance.request({ expectedStep = 7 }))
assertTrue(truckerServerContract.net.rpc.clientToServer.acceptOrder.mutating)
assertNil(truckerServerContract.exports.client, "server contract leaked client exports")
assertTrue(next(truckerServerContract.nui.state) == nil, "server contract leaked NUI state")

print("generated_contract_spec: ok")
