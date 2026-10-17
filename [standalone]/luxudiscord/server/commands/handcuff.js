module.exports = {
      data: {
            name: "handcuff",
            description: "Toggle handcuffs on a player",
            options: [

                  {
                        name: "id",
                        description: "The player server ID",
                        type: ApplicationCommandOptionType.Number,
                        required: true,
                  },
                  {
                        name: "state",
                        description: "Give Or Remove Handcuffs",
                        type: ApplicationCommandOptionType.Boolean,
                        required: true,
                  },
            ],
      },
      async execute(client, interaction) {
            const hasPerm = await client.checkPermission(interaction, this.data.name);
            if (!hasPerm) return;
            const id = interaction.options.getNumber("id");
            const state = interaction.options.getBoolean("state");

            const isPlayerOnline = await client.utils.IsPlayerOnline(id);
            if (!isPlayerOnline) {
                  interaction.reply({
                        content: `${client.Locale("PlayerNotFound")}`,
                        ephemeral: true,
                  });
                  return;
            }

            setImmediate(() => {
                  global.exports.jobs_creator.setHandcuffs(id, state)

                  interaction.reply({
                        content: `Handcuffs ${state ? "Applied" : "Removed"} Successfully`,
                        ephemeral: true,
                  });
            })
      },
};
