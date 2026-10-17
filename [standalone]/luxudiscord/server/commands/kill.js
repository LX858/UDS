module.exports = {
  data: {
    name: "kill",
    description: "Kills a player",
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
    const options = interaction.options;
    const name = GetPlayerName(id);
    if (!name) {
      interaction.reply({
        content: `${client.Locale("PlayerNotFound")}`,
        ephemeral: true,
      });
      return;
    }
    const result = await client.lm("KillPlayer", id);
    if (result) {
      interaction.reply({
        content: `${client.Locale("KillSuccess")}`,
        ephemeral: true,
      });
      client.utils.log.info(interaction);
    }
  },
};
