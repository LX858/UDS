module.exports = {
  data: {
    name: "playerlist",
    description: "Shows a list of online players",
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const players = await client.RefreshPlayers();
    const online = players.size;
    const list = [];
    players.forEach((value, key) =>
      list.push({
        name: value.name,
        value: `Server ID: ${value.id}`,
      })
    );
    const data = {
      title: "Player List",
      description: `Online: **${online}**`,
      inline: true,
      maxPerPage: 3,
    };

    client.utils.embedBuilder(list, interaction, data);
  },
};
