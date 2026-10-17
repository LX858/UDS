module.exports = {
  data: {
    name: "bucket",
    description: "Change a player's routing bucket",
    options: [
      {
        name: "check",
        description: "Check the players current bucket",
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
        name: "set",
        description: "Change the players current bucket",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server ID",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "bucket",
            description: "The new bucket",
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
    const subCommand = interaction.options.getSubcommand();

    const isOnline = await client.utils.IsPlayerOnline(id);
    if (!isOnline) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }

    if (subCommand === "check") {
      const currentBucket = await client.utils.getBucket(id);
      interaction.reply({
        content: `Player ${id} current bucket: ${currentBucket}`,
        ephemeral: true,
      });
    } else if (subCommand === "set") {
      const newBucket = interaction.options.getNumber("bucket");
      await client.utils.setBucket(id, newBucket);
      interaction.reply({
        content: `Player ${id} bucket changed to ${newBucket}`,
        ephemeral: true,
      });
      client.utils.log.info(interaction, true);
    }
  },
};
