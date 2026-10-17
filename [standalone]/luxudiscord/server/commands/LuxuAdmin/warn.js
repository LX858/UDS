module.exports = {
  data: {
    name: "warn",
    description: client.Locale("WarnPlayer"),
    options: [
      {
        name: "give",
        description: client.Locale("GiveWarn"),
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "Player Server ID",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "reason",
            description: client.Locale("Reason"),
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "clear",
        description: client.Locale("ClearWarnings"),
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "Player Server ID",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const authorName = interaction.member.user.tag;
    const subCommand = interaction.options.getSubcommand();
    const serverID = interaction.options.getString("id");

    const isPlayerOnline = await client.utils.IsPlayerOnline(serverID);

    if (!isPlayerOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    try {
      if (subCommand === "give") {
        const reason = await interaction.options.getString("reason");
        const result = await client.globalExports(
          "LuxuAdmin",
          "WarnPlayer",
          serverID,
          reason,
          authorName
        );
        if (result) {
          interaction.reply({
            content: `${client.Locale("WarnGiven")}`,
            ephemeral: true,
          });
          client.utils.log.info(interaction, true);
        } else {
          interaction.reply({
            content: `${client.Locale("WarnNotGiven")}`,
            ephemeral: true,
          });
        }
      } else if (subCommand === "clear") {
        const result = await client.globalExports(
          "LuxuAdmin",
          "ClearWarnings",
          serverID,
          authorName
        );
        if (result) {
          interaction.reply({
            content: `${client.Locale("WarningsCleared")}`,
            ephemeral: true,
          });
          client.utils.log.info(interaction, true);
        } else {
          interaction.reply({
            content: `${client.Locale("WarningsNotCleared")}`,
            ephemeral: true,
          });
        }
      }
    } catch (e) {
      console.error("Error banning player", e);
    }
  },
};
