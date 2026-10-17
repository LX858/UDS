var __create = Object.create;
var __getProtoOf = Object.getPrototypeOf;
var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
function __accessProp(key) {
    return this[key];
}
var __toESMCache_node;
var __toESMCache_esm;
var __toESM = (mod, isNodeMode, target) => {
    var canCache = mod != null && typeof mod === "object";
    if (canCache) {
        var cache = isNodeMode
            ? (__toESMCache_node ??= new WeakMap())
            : (__toESMCache_esm ??= new WeakMap());
        var cached = cache.get(mod);
        if (cached) return cached;
    }
    target = mod != null ? __create(__getProtoOf(mod)) : {};
    const to =
        isNodeMode || !mod || !mod.__esModule
            ? __defProp(target, "default", { value: mod, enumerable: true })
            : target;
    for (let key of __getOwnPropNames(mod))
        if (!__hasOwnProp.call(to, key))
            __defProp(to, key, {
                get: __accessProp.bind(mod, key),
                enumerable: true,
            });
    if (canCache) cache.set(mod, to);
    return to;
};

// shared/utils.js
var import_node_crypto = __toESM(require("node:crypto"));
function GenUUID() {
    const randomBytes = import_node_crypto.default.randomBytes(16);
    randomBytes[6] = (randomBytes[6] & 15) | 64;
    randomBytes[8] = (randomBytes[8] & 63) | 128;
    const byteGroups = [
        randomBytes.slice(0, 4),
        randomBytes.slice(4, 6),
        randomBytes.slice(6, 8),
        randomBytes.slice(8, 10),
        randomBytes.slice(10, 16),
    ];
    const uuid = byteGroups.map((group) => group.toString("hex")).join("-");
    return uuid;
}
function randomChar() {
    const chars =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    return chars.charAt(Math.floor(Math.random() * chars.length));
}
function FormatDate(date) {
    const d = new Date(date);
    const year = d.getFullYear();
    const month = d.getMonth() + 1;
    const day = d.getDate();
    const hour = d.getHours();
    const min = d.getMinutes();
    const sec = d.getSeconds();
    return `${year}-${month}-${day} ${hour}:${min}:${sec}`;
}
exports("randomChar", randomChar);
exports("GenUUID", GenUUID);
exports("FormatDate", FormatDate);
