module.exports = {
  data: {
    name: "video",
    description: "(experimental) Takes a small video of the player's POV",
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

    interaction.reply({
      content:
        "THIS COMMAND IS DISABLED DUE TO PERFOMANCE AND STABILITY ISSUES",
      ephemeral: true,
    });

    return;

    await interaction.reply({
      content: "Taking screenshots, please wait...",
      ephemeral: true,
    });

    const screenshotAmount = client.config?.Video?.frames;
    const screenshotInterval = client.config?.Video?.interval;

    const screenshots = await takeScreenshots(
      client,
      source,
      screenshotAmount,
      screenshotInterval
    );

    if (!screenshots || screenshots.length === 0) {
      interaction.editReply({
        content: "Failed to take screenshots ❌",
        ephemeral: true,
      });
      return;
    }

    const videoPath = `${client.ResourceDir}player_screenshots.webm`;
    await client.utils.WebmFromBase64(screenshots, videoPath);
    const coords = await client.utils.GetPlayerCoords(source);

    const videoBuffer = await fs.promises.readFile(videoPath);
    const attachment = new AttachmentBuilder(videoBuffer, {
      name: "player_screenshots.webm",
    });

    interaction.editReply({
      content: `Player ${source} Coords: vector3(${coords[0].toFixed(
        2
      )}, ${coords[1].toFixed(2)}, ${coords[2].toFixed(2)})`,
      files: [attachment],
      ephemeral: true,
    });

    // Delete the video file after sending it
    fs.unlinkSync(videoPath);
  },
};

async function takeScreenshots(client, source, count, interval) {
  const screenshots = [];
  const isOnline = await client.utils.IsPlayerOnline(source);
  if (!isOnline) return [];
  for (let i = 0; i < count; i++) {
    const screenshot = await client.utils.takePlayerScreenshot(source);
    if (screenshot) {
      screenshots.push(screenshot);
    } else {
      console.error("Failed to take screenshot");
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }

  return screenshots;
}
