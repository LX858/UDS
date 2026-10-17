module.exports = {
  data: {
    name: "resource",
    description: "Server resources management",
    options: [
      {
        name: "refresh",
        description: "Refreshes the list of resources and their fxmanifest",
        type: ApplicationCommandOptionType.Subcommand,
      },
      {
        name: "list",
        description: "Lists all resources",
        type: ApplicationCommandOptionType.Subcommand,
      },
      {
        name: "state",
        description: "Gets the state of a resource",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "name",
            description: "The resource name",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "ensure",
        description: "Starts/Restarts a resource",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "name",
            description: "The resource name",
            type: ApplicationCommandOptionType.String,
            required: true,
          },
        ],
      },
      {
        name: "stop",
        description: "Stops a resource",
        type: ApplicationCommandOptionType.Subcommand,
        options: [
          {
            name: "name",
            description: "The resource name",
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

    const subcommand = interaction.options.getSubcommand();

    if (subcommand === "refresh") {
      // Checks if the resource has the ace permission for command
      const canRefresh = await IsPrincipalAceAllowed(
        `resource.${client.ResourceName}`,
        "command"
      );

      if (!canRefresh) {
        interaction.reply({
          content: `${"Missing ace permission for command, check documentation."}`,
          ephemeral: true,
        });
        return;
      }
      ExecuteCommand("refresh");
      interaction.reply({
        content: `${client.Locale("ResourceRefreshSuccess")}`,
        ephemeral: true,
      });
    } else if (subcommand === "state") {
      const name = interaction.options.getString("name");
      const state = await GetResourceState(name);

      interaction.reply({
        content: `Resource **${name}** state: ${state}`,
        ephemeral: true,
      });
    } else if (subcommand === "stop") {
      const name = interaction.options.getString("name");
      const state = await GetResourceState(name);
      if (state !== "started") {
        interaction.reply({
          content: `${client.Locale("ResourceWasntRunning")}`,
          ephemeral: true,
        });
        return;
      }

      await StopResource(name);
      interaction.reply({
        content: `${name} ${client.Locale("ResourceStopSuccess")}`,
        ephemeral: true,
      });
    } else if (subcommand === "ensure") {
      try {
        const name = interaction.options.getString("name");
        if (name === client.ResourceName || name === "LuxuAdmin") {
          interaction.reply({
            content: `${"Restart the discord bot not allowed"}`,
            ephemeral: true,
          });
          return;
        }

        const state = await GetResourceState(name);

        if (state !== "missing" && state !== "unknown") {
          if (state !== "stopped" && state !== "uninitialized") {
            await StopResource(name);
          }
          if (state !== "starting") await StartResource(name);
          interaction.reply({
            content: `${name} ${client.Locale("ResourceEnsureSuccess")}`,
            ephemeral: true,
          });
        } else {
          interaction.reply({
            content: `${client.Locale("ResourceEnsureFailed")}`,
            ephemeral: true,
          });
        }
      } catch (e) {
        console.error(e);
      }
    } else if (subcommand === "list") {
      const { resources, resourceCount } = await this.getResourceList();

      const embed = new EmbedBuilder();
      embed.setTitle(`${client.Locale("Resource List")}`);
      embed.setDescription(`Resources: ${resourceCount}`);

      const embeds = [];
      const maxFields = 15;

      for (let i = 0; i < resources.length; i += maxFields) {
        const resources_list = resources.slice(i, i + maxFields);
        const fields = [];

        for (const resource of resources_list) {
          fields.push({
            name: `---`,
            value: `${resource}`,
          });
        }

        const embed = await new EmbedBuilder()
          .setTitle("Resource List")
          .setDescription(`All the resources in your server`)
          .setColor(0xff0000)
          .addFields(fields);

        embeds.push(embed);
      }

      let currentPage = 0;

      const btn1 = new ButtonBuilder()
        .setCustomId("previous")
        .setLabel("Previous")
        .setStyle(ButtonStyle.Secondary)
        .setDisabled(true);
      const btn2 = new ButtonBuilder()
        .setCustomId("next")
        .setLabel("Next")
        .setStyle(ButtonStyle.Primary)
        .setDisabled(currentPage === embeds.length - 1 ? true : false);

      const row = new ActionRowBuilder().addComponents(btn1, btn2);

      const filter = (interaction) =>
        interaction.customId === "previous" || interaction.customId === "next";

      const message = await interaction.reply({
        embeds: [embeds[currentPage]],
        components: [row],
        ephemeral: true,
      });

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
    }
  },

  async getResourceList() {
    const resourceCount = GetNumResources();
    let resources = [];
    for (let i = 0; i < resourceCount; i++) {
      const resource = GetResourceByFindIndex(i);
      if (resource && GetResourceState(resource) == "started") {
        resources.push(resource);
      }
    }
    return { resources, resourceCount };
  },
};
