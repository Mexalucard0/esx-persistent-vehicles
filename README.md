# esx-persistent-vehicles

This mod prevents vehicles from disappearing in OneSync ESX multiplayer servers. It can also respawn vehicles in their previous location after a server restart.

## Requirements
FiveM Version >=2443

OneSync - This mod will not work without OneSync.

esx_vehicleshop

## Installation

Download from the releases tab in GitHub. Extract and place the enc0ded-persistent-vehicles in your resources folder. Start the resource.

```bash
start esx-persistent-vehicles
```

Check config.lua and ensure the details match your database schema.

## Usage

To make a vehicle persistent, pass it's license plate to the event below. This event cannot be called on the client with TriggerServerEvent, it must be called server side.
```lua
TriggerEvent('persistent-vehicles/register-vehicle', plate)
```
Stop a vehicle from being persistent and allow it to be removed as normal. Does not delete the vehicle.
```lua
TriggerEvent('persistent-vehicles/forget-vehicle', plate)
```
Before you shutdown your server you will need to save the vehicles to file. This will ensure that the vehicles spawn in the exact same location when the server comes back online.
```lua
TriggerEvent('persistent-vehicles/save-vehicles-to-file')
```
Alternatively you can stop the resource which will do this automatically.
```lua
StopResource('esx-persistent-vehicles')
```

## Console
Cull persistent vehicles
```bash
pv-cull <number of vehicles>
```
Unpersist vehicles
```bash
pv-forget-all
```
Toggle console debugging messages
```bash
pv-toggle-debugging
```
Save all persistent vehicles to file. Can be called before reboot.
```bash
pv-save-to-file
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Support
[Discord](https://discord.gg/rhQhZWM)

## License
[MIT](https://choosealicense.com/licenses/mit/)