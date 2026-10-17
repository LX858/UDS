module.exports = {
  data: {
    name: "time",
    description: "Change the time of the server",
    options: [
      {
        name: "hours",
        description: "Hours of the server",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
      {
        name: "minutes",
        description: "Minutes of the server",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    //
    const hours = interaction.options.getNumber("hours");
    const minutes = interaction.options.getNumber("minutes");
    try {
      const result = await client.lm("SetTime", hours, minutes);
      if (result) {
        interaction.reply({
          content: `${client.Locale("TimeSet")}`,
          ephemeral: true,
        });
      }
    } catch (e) {
      console.log("error changing time", e);
      interaction.reply({
        content: `${client.Locale("TimeNotSet")}`,
        ephemeral: true,
      });
    }
  },
};
