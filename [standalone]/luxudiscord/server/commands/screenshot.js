module.exports = {
  data: {
    name: "screenshot",
    description: "Takes a screenshot of the player's POV",
    options: [
      {
        name: "id",
        description: "The server id of the player (online)",
        type: ApplicationCommandOptionType.Number,
        required: true,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;

    const source = interaction.options.getNumber("id");
    let screenshot = await client.utils.takePlayerScreenshot(source);
    if (!screenshot) {
      interaction.reply({
        content: "Failed to take screenshot",
        ephemeral: true,
      });
      return;
    }
    const buffer = new Buffer.from(screenshot.split(",")[1], "base64");
    const attachment = new AttachmentBuilder(buffer, {
      name: "screenshot.jpg",
    });
    const coords = await client.utils.GetPlayerCoords(source);

    const embed = await new EmbedBuilder()
      .setTitle(`Player ${source} screenshot`)
      .setDescription(
        `Coords: vector3(${coords[0].toFixed(2)}, ${coords[1].toFixed(
          2
        )}, ${coords[2].toFixed(2)})`
      )
      .setImage("attachment://screenshot.jpg");

    interaction.reply({
      embeds: [embed],
      files: [attachment],
    });
  },
};
