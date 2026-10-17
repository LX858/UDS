module.exports = {
  data: {
    name: "banlist",
    description: client.Locale("ShowsBanlist"),
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const banlist = await client.utils.getbanlist();

    if (typeof banlist === "string") {
      banlist = JSON.parse(banlist);
    }
    if (!banlist || banlist.length === 0) {
      interaction.reply({
        content: `${client.Locale("NoBans")}`,
        ephemeral: true,
      });
      return;
    }

    const embeds = [];
    const maxPlayersPerEmbed = 3;

    for (let i = 0; i < banlist.length; i += maxPlayersPerEmbed) {
      const players = banlist.slice(i, i + maxPlayersPerEmbed);
      const fields = [];

      for (const player of players) {
        fields.push(
          {
            name: `${client.Locale("Player")}`,
            value: `${player.name}`,
            inline: true,
          },
          {
            name: `${client.Locale("Reason")}`,
            value: `${player.reason}`,
            inline: true,
          },
          {
            name: "Identifiers:",
            value: `${player.identifiers}`,
            inline: true,
          },
          { name: `${client.Locale("GivenBy")}`, value: `${player.givenby}` },
          {
            name: `${client.Locale("BanDate")}`,
            value: `<t:${Math.floor(player.date)}:d>`,
          },
          {
            name: `${client.Locale("Expires")}`,
            value:
              player.expiration !== 0
                ? `<t:${Math.floor(player.expiration)}:d>`
                : `${client.Locale("Never")} - **${client.Locale(
                    "Permanent"
                  )}**`,
          },
          { name: "\u200B", value: "\u200B" }
        );
      }

      const embed = await new EmbedBuilder()
        .setTitle("Banlist")
        .setDescription(`${client.Locale("AListOfPlayersBanned")}`)
        .setColor(0xff0000)
        .addFields(fields);

      embeds.push(embed);
    }

    if (banlist) {
      let currentPage = 0;

      const btn1 = new ButtonBuilder()
        .setCustomId("previous")
        .setLabel(client.Locale("Previous"))
        .setStyle(ButtonStyle.Secondary)
        .setDisabled(true);
      const btn2 = new ButtonBuilder()
        .setCustomId("next")
        .setLabel(client.Locale("Next"))
        .setStyle(ButtonStyle.Primary)
        .setDisabled(currentPage === embeds.length - 1 ? true : false);

      const row = new ActionRowBuilder().addComponents(btn1, btn2);

      const message = await interaction.reply({
        embeds: [embeds[currentPage]],
        components: [row],
        ephemeral: true,
      });

      const filter = (interaction) =>
        interaction.customId === "previous" || interaction.customId === "next";

      const collector = message.createMessageComponentCollector({
        filter,
        time: 60000,
      });

      collector.on("collect", async (interaction) => {
        if (interaction.customId === "previous") {
          currentPage--;
        } else if (interaction.customId === "next") {
          currentPage++;
        }

        if (currentPage === 0) {
          row.components[0].setDisabled(true);
        } else {
          row.components[0].setDisabled(false);
        }

        if (currentPage === embeds.length - 1) {
          row.components[1].setDisabled(true);
        } else {
          row.components[1].setDisabled(false);
        }

        await interaction.update({
          embeds: [embeds[currentPage]],
          components: [row],
        });
      });

      collector.on("end", async () => {
        row.components.forEach((component) => component.setDisabled(true));
        await message.edit({ components: [row] });
      });
    } else {
      interaction.reply({
        content: client.Locale("BanListNotFound"),
        ephemeral: true,
      });
    }
  },
};
