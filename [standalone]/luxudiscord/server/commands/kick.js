module.exports = {
  data: {
    name: "kick",
    description: "Kicks a player",
    options: [
      {
        name: "player",
        description: "Kick a player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "reason",
            description: "Kick reason",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "all",
        description: "Kicks everyone in the server",
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
      const reason = interaction.options.getString("reason");
      if (client.utils.kickplayer(id, reason)) {
        interaction.reply({
          content: `${client.Locale("KickSuccess")}`,
          ephemeral: true,
        });
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
      }
    } else if (subCommand === "all") {
      const confirmationEmbed = new EmbedBuilder()
        .setTitle(`${client.Locale("ConfirmKick")}`)
        .setColor("Red");

      const confirmButton = new ButtonBuilder()
        .setCustomId("confirm")
        .setLabel("Confirm")
        .setStyle(ButtonStyle.Success);
      const denyButton = new ButtonBuilder()
        .setCustomId("deny")
        .setLabel("Canel")
        .setStyle(ButtonStyle.Danger);

      const row = new ActionRowBuilder().addComponents(
        confirmButton,
        denyButton
      );

      const message = await interaction.reply({
        embeds: [confirmationEmbed],
        components: [row],
        ephemeral: true,
      });

      const filter = (interaction) =>
        interaction.customId === "confirm" || interaction.customId === "deny";

      const collector = message.createMessageComponentCollector({
        filter,
        time: 60000,
      });

      collector.on("collect", async (interaction) => {
        if (interaction.customId === "confirm") {
          setImmediate(() => {
            const indexs = GetNumPlayerIndices();
            for (let i = 0; i <= indexs; i++) {
              if (GetPlayerFromIndex(i)) {
                DropPlayer(i, `${client.Locale("KickAllReason")}`);
              }
            }
          });
          interaction.reply({
            content: reason,
            ephemeral: true,
          });
        } else {
          interaction.reply({
            content: `${client.Locale("KickAllCancelled")}`,
            ephemeral: true,
          });
        }
      });
    }
  },
};
