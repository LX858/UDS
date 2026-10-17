module.exports = {
  data: {
    name: "staff",
    description: client.Locale("CheckStaff"),
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    const staff = await client.utils.GetStaffList();

    if (staff.length === 0) {
      interaction.reply({
        content: `${client.Locale("NoStaff")}`,
        ephemeral: true,
      });
    } else {
      const data = {
        title: `${client.Locale("StaffOnline")}`,
        description: `${client.Locale("Total")}: ${staff.length}`,
        maxPerPage: 4,
      };

      client.utils.embedBuilder(staff, interaction, data);
    }
  },
};
