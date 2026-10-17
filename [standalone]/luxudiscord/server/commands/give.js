function weapon_list() {
  return require(`${ResourceRootDir}/server/misc/weapons.json`).slice(0, 25);
}
function ammo_list() {
  return require(`${ResourceRootDir}/server/misc/ammo.json`).slice(0, 25);
}

// Discord has a limit of 25 choices per option

module.exports = {
  data: {
    name: "give",
    description: "Give something to a player",
    options: [
      {
        name: "item",
        description: "Give item to player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "item",
            description: "item name",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "amount",
            description: "amount",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "weapon",
        description: "Give weapon to player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "weapon",
            description: "Weapon name",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: weapon_list(),
          },
        ],
      },
      {
        name: "ammo",
        description: "Give ammunition  to player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "ammunition",
            description: "ammunition name",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: ammo_list(),
          },
          {
            name: "amount",
            description: "amount",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const id = interaction.options.getNumber("id");

    const isPlayerOnline = await client.utils.IsPlayerOnline(id);
    if (!isPlayerOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    const subCommand = interaction.options.getSubcommand();

    if (subCommand === "weapon") {
      const weapon = interaction.options.getString("weapon");
      const result = await client.utils.giveWeapon(id, weapon);

      if (result) {
        interaction.reply({
          content: `${client.Locale("WeaponGiven")}`,
          ephemeral: true,
        });
      } else {
        interaction.reply({
          content: `${client.Locale("WeaponNotGiven")}`,
          ephemeral: true,
        });
      }
      return;
    }

    const amount = interaction.options.getNumber("amount");

    let item;
    if (subCommand === "item") {
      item = interaction.options.getString("item");
    } else if (subCommand === "ammo") {
      item = interaction.options.getString("ammunition");
    }
    const result = await client.utils.giveItem(id, item, amount);

    if (result) {
      interaction.reply({
        content: `${client.Locale("ItemGiven")}`,
        ephemeral: true,
      });
    } else {
      interaction.reply({
        content: `${client.Locale("ItemNotGiven")}`,
        ephemeral: true,
      });
    }
  },
};
