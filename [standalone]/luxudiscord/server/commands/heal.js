module.exports = {
  data: {
    name: "heal",
    description: "Heals a player or all players",
    options: [
      {
        name: "player",
        description: "Heal a player",
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
        description: "Heal all players",
        type: ApplicationCommandOptionType.Subcommand,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const Subcommand = interaction.options.getSubcommand();

    if (Subcommand === "player") {
      const id = interaction.options.getNumber("id");
      const isPlayerOnline = await client.utils.IsPlayerOnline(id);

      if (!isPlayerOnline) {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }

      client.lib.triggerClientCallback("LuxuModules:Client:HealSelf", id);

      interaction.reply({
        content: `${client.Locale("PlayerHealSuccess")}`,
        ephemeral: true,
      });
      client.utils.log.info(interaction, true);
    } else if (Subcommand === "all") {
      const players = await client.globalExports(
        client.ResourceName,
        "GetPlayers"
      );
      for (const player of players) {
        client.lib.triggerClientCallback("LuxuModules:Client:HealSelf", player);
      }

      interaction.reply({
        content: `${client.Locale("EveryoneHealSuccess")}`,
        ephemeral: true,
      });
      client.utils.log.info(interaction, true);
    }
  },
};
