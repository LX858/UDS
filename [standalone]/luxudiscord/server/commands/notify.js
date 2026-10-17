module.exports = {
  data: {
    name: "notify",
    description: "Notify a player",
    options: [
      {
        name: "player",
        description: "Notifies a player",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "type",
            description: "Type of notification",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              { name: "🔵 Info", value: "info" },
              { name: "🟡 Warning", value: "warning" },
              { name: "🟢 Success", value: "success" },
              { name: "🔴 Error", value: "error" },
            ],
          },
          {
            name: "message",
            description: "Message content",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "duration",
            description: "Duration of the notification (milliseconds)",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
        ],
      },
      {
        name: "everyone",
        description: "Notifies everyone on the server",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "type",
            description: "Type of notification",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              { name: "🔵 Info", value: "info" },
              { name: "🟡 Warning", value: "warning" },
              { name: "🟢 Success", value: "success" },
              { name: "🔴 Error", value: "error" },
            ],
          },
          {
            name: "message",
            description: "Message content",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
          {
            name: "duration",
            description: "Duration of the notification (milliseconds)",
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
    const subCommand = interaction.options.getSubcommand();
    const type = interaction.options.getString("type");
    const message = interaction.options.getString("message");
    const duration = interaction.options.getNumber("duration");

    let id;
    if (subCommand === "player") {
      id = interaction.options.getNumber("id");
      const name = await GetPlayerName(id);
      if (typeof name !== "string") {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
        return;
      }

      client.utils.notifyPlayer(id, type, message, duration);
      client.utils.log.info(interaction, true);
      interaction.reply({
        content: `${client.Locale("NotifySuccess")}`,
        ephemeral: true,
      });
      return;
    }

    client.utils.notifyAll(type, message, duration);
    client.utils.log.info(interaction, true);
    interaction.reply({
      content: `${client.Locale("NotifySuccess")}`,
      ephemeral: true,
    });
  },
};
