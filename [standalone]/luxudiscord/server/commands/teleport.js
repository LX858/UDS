module.exports = {
  data: {
    name: "tp",
    description: "Teleport a player",
    options: [
      // {
      //   name: "coords",
      //   description: "Teleports a player to coords",
      //   type: ApplicationCommandOptionType.Subcommand,
      //   options: [
      //     {
      //       name: "id",
      //       description: "The player server id",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "x",
      //       description: "The x coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "y",
      //       description: "The y coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "z",
      //       description: "The z coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //   ],
      // },
      // {
      //   name: "coords_vector3",
      //   description: "Teleports a player to coords, using vector3",
      //   type: ApplicationCommandOptionType.Subcommand,
      //   options: [
      //     {
      //       name: "id",
      //       description: "The player server id",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "vector3",
      //       description: "The vector 3 coords, example: vector3(x,y,z)",
      //       type: ApplicationCommandOptionType.String,
      //       required: true,
      //     },
      //   ],
      // },
      // {
      //   name: "player",
      //   description: "Teleports a player to another player",
      //   type: ApplicationCommandOptionType.Subcommand,
      //   options: [
      //     {
      //       name: "id1",
      //       description: "The player server id, that will be teleported",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "id2",
      //       description: "The player server id, to get coords from",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //   ],
      // },
      // {
      //   name: "all",
      //   description: "Teleports all players",
      //   type: ApplicationCommandOptionType.Subcommand,
      //   options: [
      //     {
      //       name: "x",
      //       description: "The x coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "y",
      //       description: "The y coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //     {
      //       name: "z",
      //       description: "The z coords",
      //       type: ApplicationCommandOptionType.Number,
      //       required: true,
      //     },
      //   ],
      // },
      // {
      //   name: "all-vector3",
      //   description: "Teleports all players",
      //   type: ApplicationCommandOptionType.Subcommand,
      //   options: [
      //     {
      //       name: "vector3",
      //       description: "The vector 3 coords, example: vector3(x,y,z)",
      //       type: ApplicationCommandOptionType.String,
      //       required: true,
      //     },
      //   ],
      // },
      {
        name: "location",
        description: "Teleports a player to a preset location",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "id",
            description: "The player server id",
            type: ApplicationCommandOptionType.Number,
            required: true,
          },
          {
            name: "place",
            description: "Select a location",
            type: ApplicationCommandOptionType.String,
            required: true,
            choices: [
              {
                name: "🏥 Bệnh viện mới 1",
                value: "new_hospital",
              },
              {
                name: "🚗 Garage trung tâm",
                value: "central_garage",
              },
            ],
          },
          {
            name: "mota",
            description: "Mô tả / Lý do dịch chuyển",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    //
    const subCommand = interaction.options.getSubcommand();

    if (subCommand === "coords") {
      const id = interaction.options.getNumber("id");
      const x = interaction.options.getNumber("x");
      const y = interaction.options.getNumber("y");
      const z = interaction.options.getNumber("z");
      const targetName = await client.utils.GetPlayerName(id);
      const targetStr = targetName ? `ID ${id} (${targetName})` : `ID ${id}`;

      if (await client.utils.teleport(id, x, y, z)) {
        interaction.reply({
          content: `✅ **Đã dịch chuyển ${targetStr}** tới tọa độ **X: ${x}, Y: ${y}, Z: ${z}**!`,
          ephemeral: true,
        });
        client.utils.log.teleport(interaction, {
          subcommand: "coords",
          targetId: id,
          targetName: targetName,
          coords: { x, y, z },
        });
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
      }
    } else if (subCommand === "coords_vector3") {
      const id = interaction.options.getNumber("id");
      const vector3 = interaction.options.getString("vector3");
      const targetName = await client.utils.GetPlayerName(id);
      const targetStr = targetName ? `ID ${id} (${targetName})` : `ID ${id}`;
      const coords = await client.utils.convertVector3(vector3);
      if (!coords) {
        interaction.reply({
          content: `${client.Locale("InvalidVector3")}`,
          ephemeral: true,
        });
        return;
      }
      const { x, y, z } = coords;
      if (await client.utils.teleport(id, x, y, z)) {
        interaction.reply({
          content: `✅ **Đã dịch chuyển ${targetStr}** tới tọa độ **X: ${x}, Y: ${y}, Z: ${z}**!`,
          ephemeral: true,
        });
        client.utils.log.teleport(interaction, {
          subcommand: "coords_vector3",
          targetId: id,
          targetName: targetName,
          coords: { x, y, z },
        });
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
      }
    } else if (subCommand === "player") {
      const id1 = interaction.options.getNumber("id1");
      const id2 = interaction.options.getNumber("id2");
      const targetName1 = await client.utils.GetPlayerName(id1);
      const targetName2 = await client.utils.GetPlayerName(id2);
      const targetStr1 = targetName1 ? `ID ${id1} (${targetName1})` : `ID ${id1}`;
      const targetStr2 = targetName2 ? `ID ${id2} (${targetName2})` : `ID ${id2}`;

      if (await client.utils.teleportToPlayer(id1, id2)) {
        interaction.reply({
          content: `✅ **Đã dịch chuyển ${targetStr1}** tới người chơi **${targetStr2}**!`,
          ephemeral: true,
        });
        client.utils.log.teleport(interaction, {
          subcommand: "player",
          targetId: id1,
          targetName: targetName1,
          destPlayerId: id2,
          destPlayerName: targetName2,
        });
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
      }
    } else if (subCommand === "all") {
      const x = interaction.options.getNumber("x");
      const y = interaction.options.getNumber("y");
      const z = interaction.options.getNumber("z");
      client.utils.teleportAll(x, y, z);
      interaction.reply({
        content: `✅ **Đã dịch chuyển TẤT CẢ người chơi** tới tọa độ **X: ${x}, Y: ${y}, Z: ${z}**!`,
        ephemeral: true,
      });
      client.utils.log.teleport(interaction, {
        subcommand: "all",
        coords: { x, y, z },
      });
    } else if (subCommand === "all-vector3") {
      const vector3 = interaction.options.getString("vector3");
      const coords = await client.utils.convertVector3(vector3);
      if (!coords) {
        interaction.reply({
          content: `${client.Locale("InvalidVector3")}`,
          ephemeral: true,
        });
        return;
      }
      client.utils.teleportAll(coords.x, coords.y, coords.z);
      interaction.reply({
        content: `✅ **Đã dịch chuyển TẤT CẢ người chơi** tới tọa độ **X: ${coords.x}, Y: ${coords.y}, Z: ${coords.z}**!`,
        ephemeral: true,
      });
      client.utils.log.teleport(interaction, {
        subcommand: "all-vector3",
        coords: coords,
      });
    } else if (subCommand === "location") {
      const id = interaction.options.getNumber("id");
      const place = interaction.options.getString("place");
      const mota = interaction.options.getString("mota");
      const targetName = await client.utils.GetPlayerName(id);

      // Preset locations
      const locations = {
        new_hospital: { x: 273.0461, y: -1428.0923, z: 29.4668, h: 233.0205 },
        central_garage: { x: 218.5355, y: -801.7626, z: 30.7503, h: 206.5815 },
      };

      const locationNames = {
        new_hospital: "Bệnh viện mới",
        central_garage: "Garage trung tâm",
      };

      const location = locations[place];
      if (location && await client.utils.teleport(id, location.x, location.y, location.z)) {
        const targetStr = targetName ? `ID ${id} (${targetName})` : `ID ${id}`;
        const placeStr = locationNames[place] || place;
        let replyMsg = `✅ **Đã dịch chuyển ${targetStr}** tới **${placeStr}**!`;
        if (mota) {
          replyMsg += `\n📝 **Mô tả / Lý do:** ${mota}`;
        }
        interaction.reply({
          content: replyMsg,
          ephemeral: true,
        });
        client.utils.log.teleport(interaction, {
          subcommand: "location",
          targetId: id,
          targetName: targetName,
          locationName: placeStr,
          mota: mota || undefined,
          coords: { x: location.x, y: location.y, z: location.z },
        });
      } else {
        interaction.reply({
          content: `${client.Locale("PlayerNotFound")}`,
          ephemeral: true,
        });
      }
    }
  },
};
