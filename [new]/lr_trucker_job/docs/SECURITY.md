# Security

The v2 security model assumes every boundary input is untrusted.

## Boundaries

- NUI callback payloads are browser-originated and must be validated in Lua.
- Synchronized NUI state is browser-writable and remains untrusted even after TypeBox
  validation and canonical revision sequencing in the Lua bridge.
- Client net event payloads are player-originated and must be authorized server-side.
- Public exports are cross-resource calls and must validate arguments.
- Config values are deployment inputs and should be checked before use.

## Required Checks

Server-side state transitions must verify:

- player identity from `source`;
- permission or role;
- ownership of target entities, items, accounts, or jobs;
- distance and world state when relevant;
- amount bounds and currency/item identifiers;
- replay and spam resistance for expensive actions.

NUI actions must not directly grant money, inventory, roles, or persistent state.
Decorated store assignment, low-level `state.set`/`state.patch`, and a synchronized state
watcher must never replace an authorized server RPC. Treat synchronized state as UI/client
intent or presentation data; any authoritative mutation still verifies transport-provided
`source`, permissions, entity ownership, distance, world state, bounds, and replay risk on
the server.

## Standalone Dependency Policy

Core v2 modules must not require framework or ox globals. Side-specific bridge boundaries
under `client/bridges/` and `server/bridges/` may integrate with ESX, QBCore, or Qbox, but
those bridges must:

- detect missing resources before use;
- fail closed;
- keep external error details out of player-facing messages;
- avoid changing the core public API shape.
- return normalized DTOs instead of raw core/player objects;
- remove every raw framework event handler during application disposal.

Framework loaded/data events are hints, not authorization boundaries. A client can reach
networked framework events and all client state is untrusted. Server mutations must still
derive identity from transport-provided `source` and validate permission, ownership,
distance, bounds, world state, and replay risk. Feature modules must use
`context.services.framework`; raw framework exports/events are forbidden outside the exact
bridge boundary files.

## Logging

Security-relevant failures should log enough context for operators to diagnose the
attempt without leaking secrets or raw tokens. Logs should include the action name,
source, validation failure category, and module owner.
