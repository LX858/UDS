module.exports = {
  data: {
    name: "weather",
    description: "Change server weather",
    options: [
      {
        name: "weather",
        description: "Type of weather",
        type: ApplicationCommandOptionType.String,
        required: true,
        choices: [
          {
            name: "Extra Sunny",
            value: "EXTRASUNNY",
          },
          {
            name: "Clear",
            value: "CLEAR",
          },
          {
            name: "Clouds",
            value: "CLOUDS",
          },
          {
            name: "Smog",
            value: "SMOG",
          },
          {
            name: "Foggy",
            value: "FOGGY",
          },
          {
            name: "Overcast",
            value: "OVERCAST",
          },
          {
            name: "Rain",
            value: "RAIN",
          },
          {
            name: "Thunder",
            value: "THUNDER",
          },
          {
            name: "Clearing",
            value: "CLEARING",
          },
          {
            name: "Neutral",
            value: "NEUTRAL",
          },
          {
            name: "Snow",
            value: "SNOW",
          },
          {
            name: "Blizzard",
            value: "BLIZZARD",
          },
          {
            name: "Light Snow",
            value: "SNOWLIGHT",
          },
          {
            name: "Xmas",
            value: "XMAS",
          },
          {
            name: "Halloween",
            value: "HALLOWEEN",
          },
        ],
      },
    ],
  },
  async execute(client, interaction) {
    const hasPerm = await client.checkPermission(interaction, this.data.name);
    if (!hasPerm) return;
    //
    const weather = interaction.options.getString("weather");
    try {
      const result = await client.lm("SetWeather", weather);
      if (result) {
        interaction.reply({
          content: `${client.Locale("WeatherSet")}`,
          ephemeral: true,
        });
      }
    } catch (e) {
      console.log("error changing the weather", e);
      interaction.reply({
        content: `${client.Locale("WeatherNotSet")}`,
        ephemeral: true,
      });
    }
  },
};
