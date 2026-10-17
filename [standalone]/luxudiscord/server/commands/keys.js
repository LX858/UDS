module.exports = {
  data: {
    name: "car-keys",
    description: "Give a player a car keys of the current vehicle",
    options: [
      {
        name: "id",
        description: "The player server ID",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const id = interaction.options.getNumber("id");
    const result = await client.utils.GiveKeys(id);

    if (result) {
      interaction.reply({
        content: `${client.Locale("Success")}`,
        ephemeral: true,
      });
    } else {
      interaction.reply({
        content: `${client.Locale("CarKeysError")}`,
        ephemeral: true,
      });
    }
  },
};
