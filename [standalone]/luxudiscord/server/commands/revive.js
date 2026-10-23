module.exports = {
  data: {
    name: "revive",
    description: "Revive a player",
    options: [
      {
        name: "player",
        description: "Revive a player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "all",
        description: "Revive everyone",
        type: ApplicationCommandOptionType.Subcommand,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const subCommand = interaction.options.getSubcommand();

    if (subCommand === "player") {
      const id = interaction.options.getNumber("id");
      const name = GetPlayerName(id);
      if (!name) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }
      const result = await client.lm("RevivePlayer", id);
      if (result) {
        interaction.reply({
          content: `${client.Locale("ReviveSuccess")}`,
          ephemeral: true,
        });
        client.utils.log.revive(interaction, {
          subcommand: "player",
          targetId: id,
          targetName: name,
        });
      }
    } else if (subCommand === "all") {
      const result = await client.utils.reviveAll();
      if (result) {
        interaction.reply({
          content: `${client.Locale("ReviveSuccess")}`,
          ephemeral: true,
        });
        client.utils.log.revive(interaction, {
          subcommand: "all",
        });
      }
    }
  },
};
