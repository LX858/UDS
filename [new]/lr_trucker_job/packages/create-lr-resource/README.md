# create-lr-resource

Create a standalone, type-safe FiveM resource from the LR v2 template.

## Usage

```bash
npx create-lr-resource@latest --name my_resource
```

Equivalent commands:

```bash
npm create lr-resource@latest -- --name my_resource
pnpm dlx create-lr-resource@latest --name my_resource
```

Use `--output` to select the parent directory:

```bash
npx create-lr-resource@latest --name my_resource --output ./resources
```

The command creates one FiveM resource directory containing its `fxmanifest.lua`,
client, server, shared Lua code, typed contracts, tooling, tests, MobX NUI, and optional
ESX Legacy/QBCore/Qbox bridges. The generated resource remains standalone by default;
select a framework with `Config.Framework.Name` in `config.lua`.

## Requirements

- Node.js 24 or newer.
- A lowercase resource name beginning with a letter and containing only letters,
  numbers, `_`, or `-`.

The initializer refuses to overwrite a non-empty destination and rejects symbolic
links in the embedded template.

## After creation

```bash
cd my_resource
corepack enable
pnpm install --frozen-lockfile
pnpm verify
```

See the [main repository](https://github.com/Lorraxs/lr_trucker_job) for the
architecture, contracts, module-authoring guide, and migration documentation.
