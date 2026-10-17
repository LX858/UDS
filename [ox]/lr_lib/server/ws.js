const WebSocket = require("ws");
removeEventListener = function () {}; // giữ lại nếu môi trường đòi hỏi

const WS_URL = GetConvar("ws_server_url", "ws://localhost:1108/server/ws");
const WS_TOKEN = GetConvar(
  "ws_server_token",
  "z0HGNy2rJ31RFrA3xnvYxxNe0hbX2Z9mVBtTqNrjNWsBf7Hx3vpduKxSxtvCXHaH"
);
const WS_NAME = GetConvar("ws_name", "test-lorraxs");
const ResourceName = GetCurrentResourceName();

const eventHandlers = new Map();
const onReadyHandlers = new Set();
const registeredCallbacks = new Map();

const codec = msgpack.createCodec({ uint8array: true });
const pack = (d) => msgpack.encode(d, { codec });
const unpack = (d) => msgpack.decode(d, { codec });

global.msgpack_pack = pack;
global.msgpack_unpack = unpack;

let websocket = null;
let ready = false;
let connected = false;
let reconnectTimer = null;
let heartbeatTimer = null;

function safeSend(data) {
  if (!websocket || websocket.readyState !== WebSocket.OPEN) return;
  try {
    websocket.send(data);
  } catch (e) {
    console.log("[WS] Send failed:", e.message);
  }
}

function flushReadyHandlers() {
  ready = true;
  onReadyHandlers.forEach((entry) => {
    try {
      entry.handler();
    } catch (e) {
      console.error(`[WS] onReady error (${entry.resource}):`, e);
    }
  });
}

exports("WsOnReady", (handler) => {
  if (ready) handler();
  else onReadyHandlers.add({ resource: GetInvokingResource(), handler });
});

const WsRegisterEventHandler = (eventName, callback) => {
  const callbacks = eventHandlers.get(eventName);
  const invoker = GetInvokingResource();
  if (!callbacks) {
    const callbacks = new Set();
    callbacks.add({ resource: invoker, handler: callback });
    eventHandlers.set(eventName, callbacks);
  } else {
    callbacks.add({ resource: invoker, handler: callback });
  }
};
exports("WsRegisterEventHandler", WsRegisterEventHandler);

const WsTriggerClientEvent = (eventName, playerId, ...args) => {
  const packedData = global.msgpack_pack([eventName, playerId, args]);
  websocket.send(packedData);
};
exports("WsTriggerClientEvent", WsTriggerClientEvent);

const SetValidCallback = (callbackName, isValid) => {
  const resourceName = GetInvokingResource() || ResourceName;
  const callbackResource = registeredCallbacks.get(callbackName);
  if (callbackResource) {
    if (!isValid) {
      registeredCallbacks.delete(callbackName);
      return;
    }
    if (callbackResource === ResourceName) {
      return;
    }
    throw new Error(
      `Callback ${callbackName} already registered by ${callbackResource}`
    );
  }

  registeredCallbacks.set(callbackName, resourceName);
};
exports("SetValidCallback", SetValidCallback);

on("onResourceStop", (resource) => {
  eventHandlers.forEach((set) => {
    for (const cb of Array.from(set))
      if (cb.resource === resource) set.delete(cb);
  });
  for (const h of Array.from(onReadyHandlers))
    if (h.resource === resource) onReadyHandlers.delete(h);
  for (const [name, res] of Array.from(registeredCallbacks))
    if (res === resource) registeredCallbacks.delete(name);
});

WsRegisterEventHandler(
  "lr_lib_ws:validateCallback",
  (playerId, callbackName, invokingResource, key) => {
    if (!registeredCallbacks.has(callbackName)) {
      const ev = `__ws_cb_${invokingResource}`;
      WsTriggerClientEvent(ev, playerId, key, "cb_invalid");
    }
  }
);

// ---------------- Connection logic ---------------- //

function start() {
  if (reconnectTimer) clearTimeout(reconnectTimer);
  console.log(`[WS] Connecting to ${WS_URL} ...`);

  try {
    websocket = new WebSocket(`${WS_URL}?token=${WS_TOKEN}&name=${WS_NAME}`, {
      maxPayload: 128 * 1024 * 1024,
      perMessageDeflate: false,
    });
  } catch (err) {
    console.error("[WS] Create socket failed:", err);
    return scheduleReconnect();
  }

  websocket.onopen = () => {
    console.log("[WS] Connected");
    connected = true;
    ready = false;
    flushReadyHandlers();
    startHeartbeat();
  };

  websocket.onmessage = (event) => {
    let decoded;
    try {
      decoded = unpack(event.data);
    } catch {
      return console.warn("[WS] Decode failed");
    }

    const { playerId, payload } = decoded;
    if (!payload || !Array.isArray(payload)) return;
    const [eventName, args] = payload;
    const list = eventHandlers.get(eventName);
    if (!list) return;

    for (const cb of list) {
      try {
        cb.handler(playerId, ...(args || []));
      } catch (err) {
        console.error(`[WS] Handler error (${cb.resource}):`, err);
      }
    }
  };

  websocket.onclose = (e) => {
    console.log("[WS] Closed:", e.code, e.reason);
    connected = false;
    stopHeartbeat();
    scheduleReconnect();
  };

  websocket.onerror = (err) => {
    console.log("[WS] Error:", err.message);
  };
}

function startHeartbeat() {
  stopHeartbeat();
  heartbeatTimer = setInterval(() => {
    if (!websocket || websocket.readyState !== WebSocket.OPEN) return;
    websocket.ping?.();
  }, 30000);
}

function stopHeartbeat() {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
  }
}

function scheduleReconnect() {
  if (reconnectTimer) return;
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    start();
  }, 2000);
}

start();
