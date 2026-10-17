module.exports = {
  data: {
    name: "online",
    description: "Quickly know the number of online Players",
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const online = await client.utils.getOnlineCount();
    interaction.reply({
      content: `${client.Locale("PlayersOnline")}: **${online}**`,
      ephemeral: true,
    });
  },
};
