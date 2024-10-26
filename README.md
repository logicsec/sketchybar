# Weather Plugin for SketchyBar

This plugin displays current weather information in your SketchyBar, including temperature and weather conditions using Weather API.

## Prerequisites

- [SketchyBar](https://github.com/FelixKratz/SketchyBar) installed
- [Weather API](https://www.weatherapi.com/) account and API key
- `jq` installed for JSON parsing (`brew install jq`)

## Setup

1. Sign up for a free account at [Weather API](https://www.weatherapi.com/)

2. Create a `.env` file in your SketchyBar config directory:
   ```bash
   touch ~/.config/sketchybar/.env
   ```

3. Add your API key and city to the `.env` file:
   ```bash
   WEATHER_API_KEY="your_api_key_here"
   WEATHER_CITY="your_city_or_zip_here"
   ```

   - Replace `your_api_key_here` with your Weather API key
   - Replace `your_city_or_zip_here` with your city name, zip code, or coordinates
     - Examples:
       - Zip code: "40509"
       - City name: "London"
       - Coordinates: "51.5072,0.1276"

4. Make sure the `.env` file is private:
   ```bash
   chmod 600 ~/.config/sketchybar/.env
   ```

5. Add `.env` to your `.gitignore` if you're using git:
   ```bash
   echo ".env" >> .gitignore
   ```

## Weather Icons

The plugin uses SF Symbols for weather icons. Different icons are displayed based on:
- Current weather conditions
- Time of day (day/night)
- Severity of weather conditions

## Troubleshooting

If you're not seeing weather information:

1. Check your API key is correct in `.env`
2. Verify your city/location is valid
3. Check the Weather API service status
4. Look for error messages in SketchyBar's logs:
   ```bash
   tail -f /tmp/sketchybar_log
   ```

## Rate Limits

The free tier of Weather API includes:
- 1 million calls per month
- 3 day forecast
- Real-time weather
- 7 day history

This plugin makes requests every few minutes, well within these limits.

## Contributing

Feel free to submit issues and enhancement requests!

## License

This plugin is available under the MIT License.
