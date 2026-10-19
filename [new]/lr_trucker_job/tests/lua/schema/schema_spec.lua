local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertFalse(value, message)
  if value ~= false then error(message or "expected false") end
end

LR = {}
dofile("shared/core/lr.lua")
dofile("shared/core/schema.lua")

local snapshotSchema = {
  type = "object",
  required = { "count", "message" },
  properties = {
    count = { type = "integer", minimum = 0 },
    message = { type = "string", minLength = 1, maxLength = 8 },
  },
  additionalProperties = false,
}

local validateSnapshot = LR.Schema.Compile(snapshotSchema)
assertTrue(validateSnapshot({ count = 1, message = "ready" }))
assertFalse(validateSnapshot({ count = -1, message = "ready" }))
assertFalse(validateSnapshot({ count = 1, message = "" }))
assertFalse(validateSnapshot({ count = 1, message = "ready", injected = true }))
assertFalse(validateSnapshot({ count = 1.5, message = "ready" }))

local validateUnion = LR.Schema.Compile({
  anyOf = {
    { type = "string", const = "client" },
    { type = "string", const = "nui" },
  },
})
assertTrue(validateUnion("client"))
assertFalse(validateUnion("server"))

local validateArray = LR.Schema.Compile({
  type = "array",
  minItems = 1,
  maxItems = 2,
  items = { type = "integer" },
})
assertTrue(validateArray({ 1, 2 }))
assertFalse(validateArray({}))
assertFalse(validateArray({ 1, "2" }))

local compiled = LR.Schema.CompileContract({
  id = "schema_spec",
  state = {
    snapshot = { schema = snapshotSchema, default = { count = 0, message = "ready" } },
  },
  nui = { events = { toNui = {}, toClient = {} }, rpc = { toNui = {}, toClient = {} } },
  net = {
    events = { clientToServer = { changed = snapshotSchema }, serverToClient = {} },
    rpc = {
      clientToServer = {
        save = {
          request = snapshotSchema,
          response = { type = "object", properties = {}, additionalProperties = false },
          timeoutMs = 1234,
          mutating = true,
        },
      },
      serverToClient = {},
    },
  },
  exports = { client = {}, server = {} },
})

assertTrue(compiled.nui.state.snapshot.validate({ count = 0, message = "ready" }))
assertTrue(compiled.nui.state.snapshot.owner == nil, "compiled state must not retain an owner")
assertTrue(compiled.net.events.clientToServer.changed.validate({ count = 2, message = "ok" }))
assertTrue(compiled.net.rpc.clientToServer.save.request({ count = 2, message = "ok" }))
assertTrue(compiled.net.rpc.clientToServer.save.mutating)
assertTrue(compiled.net.rpc.clientToServer.save.timeoutMs == 1234)

print("schema_spec: ok")
