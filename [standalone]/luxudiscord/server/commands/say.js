module.exports = {
  data: {
    name: "say",
    description: "Create a embed message",
    options: [
      {
        name: "title",
        description: "The title of the message",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: "message",
        description: "The message to send",
        type: ApplicationCommandOptionType.String,
        required: true,
      },
      {
        name: "color",
        description: "The color of the message",
        type: ApplicationCommandOptionType.String,
        required: true,
        choices: [
          {
            name: "🔴",
            value: "Red",
          },
          {
            name: "🟢",
            value: "Green",
          },
          {
            name: "🔵",
            value: "Blue",
          },
          {
            name: "🟡",
            value: "Yellow",
          },
          {
            name: "🟣",
            value: "Purple",
          },
          {
            name: "🟠",
            value: "Orange",
          },
        ],
      },
      {
        name: "channel",
        description: "The channel to send the message to",
        type: ApplicationCommandOptionType.Channel,
        required: false,
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const title = interaction.options.getString("title");
    const message = interaction.options.getString("message");
    const color = interaction.options.getString("color");
    const targetChannel = interaction.options.getChannel("channel");

    const embed = new EmbedBuilder()
      .setTitle(title)
      .setColor(color)
      .setDescription(message);

    interaction.reply({
      content: `Message Sent`,
      ephemeral: true,
    });

    // send message to current channel
    const channel = targetChannel || interaction.channel;
    channel.send({
      embeds: [embed],
    });

    client.utils.log.info(interaction);
  },
};
