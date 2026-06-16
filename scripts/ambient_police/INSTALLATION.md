# Installation Guide

To add ambient police vehicles to your FiveM server, follow these steps:

1. The resource has been created in: `resources/[scripts]/ambient_police/`

2. Now you need to add it to your server.cfg file. Open your server.cfg file and add:
   ```
   ensure ambient_police
   ```

3. Restart your server, or use the command `refresh` followed by `start ambient_police` in the server console.

4. Once the resource is running, you can use the following in-game commands:
   - `/togglepolicecars` - Turn random police cars on/off
   - `/togglepolicehelis` - Turn police helicopters on/off
   - `/settraffic 0.8` - Set traffic density (0.0-1.0)
   - `/policestatus` - View current settings

5. All settings can be adjusted in the `config.lua` file if you want to change the defaults.

## Troubleshooting

If you encounter any issues:
- Check the server console for errors
- Make sure the resource is started (it should appear in the `/policestatus` command)
- Check that you have permission to use the commands

## Default Configuration

By default:
- Random police vehicles are enabled
- Police helicopters are enabled
- Traffic density is set to 0.8 (80% of normal GTA traffic)
- Pedestrian density is set to 0.8 (80% of normal GTA pedestrians)
