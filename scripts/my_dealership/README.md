# my_dealership

Custom vehicle dealership system for FiveM BareBones Framework.

## Features

- **E key interaction** at dealership location
- **Real-time money validation** via my_money integration
- **Secure purchase authorization** system prevents exploits
- **Automatic vehicle spawning** and registration
- **NUI-based catalog** (placeholder for frontend team)
- **Persistent vehicle ownership** via my_vehicles integration

## Dependencies

- `my_datamanager` - Core data management
- `my_money` - Money system for transactions
- `my_vehicles` - Vehicle persistence and ownership

## Installation

1. Place `my_dealership` in your resources folder
2. Ensure dependencies are loaded first in server.cfg:
   ```
   ensure my_datamanager
   ensure my_money
   ensure my_vehicles
   ensure my_dealership
   ```
3. Restart server or `refresh` and `start my_dealership`

## Configuration

Edit `config.lua` to customize:

- **Dealership location** - Where players press E to open UI
- **Spawn location** - Where purchased vehicles spawn
- **Interaction distance** - How close players need to be
- **Vehicle catalog** - Available vehicles and prices
- **Authorization timeout** - How long purchase tokens are valid

## Usage

### In-Game

1. Go to dealership location: `-57.1711, -1096.5557, 26.4224`
2. Press **E** to open dealership UI
3. Select vehicle to purchase
4. Vehicle spawns at: `-31.0018, -1090.4841, 26.1574`
5. Vehicle is automatically registered to player

### Admin Commands

Use my_money commands to give players cash:
```
/addmoney cash 100000
```

## Server API

### Events

**`my_dealership:purchaseVehicle`** (client → server)
- **Parameters:** `vehicleModel` (string)
- **Description:** Request to purchase a vehicle
- **Validation:** Checks vehicle exists, player has money
- **Response:** Triggers `purchaseSuccess` or `purchaseFailure`

**`my_dealership:purchaseSuccess`** (server → client)
- **Parameters:** `{ plate, model, name }`
- **Description:** Vehicle purchase approved
- **Action:** Spawns vehicle and triggers claim

**`my_dealership:purchaseFailure`** (server → client)
- **Parameters:** `errorMessage` (string)
- **Description:** Purchase rejected
- **Action:** Shows error to player

### Exports

**`VerifyPurchase(source, plate)`**
- **Description:** Validates purchase authorization (called by my_vehicles)
- **Parameters:**
  - `source` (number) - Player server ID
  - `plate` (string) - Vehicle plate number
- **Returns:** `boolean` - true if authorized, false otherwise
- **Note:** One-time use - authorization is consumed on verification

## Purchase Flow

```
1. Player presses E at dealership
   ↓
2. UI opens with vehicle catalog
   ↓
3. Player clicks vehicle → purchaseVehicle NUI callback
   ↓
4. Client sends my_dealership:purchaseVehicle to server
   ↓
5. Server validates:
   - Valid vehicle model
   - Player has enough cash
   ↓
6. Server removes money and creates authorization token
   ↓
7. Server sends purchaseSuccess to client with plate
   ↓
8. Client spawns vehicle and triggers my_vehicles:claimVehicle
   ↓
9. my_vehicles calls exports['my_dealership']:VerifyPurchase()
   ↓
10. Authorization verified and consumed
    ↓
11. Vehicle registered to player
```

## Security Features

### Purchase Authorization System

The dealership uses a **one-time token system** to prevent exploits:

1. **Token Generation:** When purchase is approved, server generates unique plate and stores authorization
2. **Token Storage:** `{ plate → { source, timestamp, model, price } }`
3. **Verification:** my_vehicles calls `VerifyPurchase(source, plate)` before allowing claim
4. **Token Consumption:** Authorization is deleted after verification (one-time use)
5. **Timeout:** Tokens older than 60 seconds are automatically cleaned up

This prevents:
- Players claiming vehicles they didn't purchase
- Duplicate claims of same vehicle
- Exploiting the spawn/claim process

### Input Validation

All inputs are validated:
- Source must be valid player
- Vehicle model must exist in config
- Money amounts must be positive numbers
- Plate must be valid string

## File Structure

```
my_dealership/
├── fxmanifest.lua      # Resource manifest
├── config.lua          # Configuration
├── server.lua          # Server-side logic
├── client.lua          # Client-side logic
├── html/
│   ├── index.html      # UI structure (placeholder)
│   ├── style.css       # UI styling (placeholder)
│   └── script.js       # UI logic (placeholder)
└── README.md           # This file
```

## Testing

1. **Add money to player:**
   ```
   /addmoney cash 100000
   ```

2. **Go to dealership location:**
   - Coords: `-57.1711, -1096.5557, 26.4224`

3. **Press E to open UI**

4. **Purchase a vehicle**

5. **Verify:**
   - Money was deducted
   - Vehicle spawned
   - Player put in vehicle
   - Vehicle persists (check my_vehicles data)

## Console Logs

The resource uses colored console logs for debugging:

- **^2Green^7** - Success messages
- **^3Yellow^7** - Warnings and info
- **^1Red^7** - Errors

Example output:
```
^2[my_dealership SUCCESS]^7 Player 1 purchased Truffade Adder (Plate: AB12CD34) for $50000
^2[my_dealership]^7 VerifyPurchase: Authorized and consumed for plate: AB12CD34
```

## Frontend Notes

UI files (html/) are placeholders. Frontend team should implement:

- Modern vehicle catalog grid/list
- Vehicle preview images
- Detailed vehicle stats
- Purchase confirmation modal
- Money display
- Error notifications
- Transparent backgrounds (no black boxes)
- Smooth animations

## Known Limitations

- No vehicle preview/test drive
- No vehicle customization on purchase
- Cash only (no dirty money)
- No refunds or trade-ins
- Basic placeholder UI

## Troubleshooting

**UI won't open:**
- Check you're within interaction distance (2.0 units)
- Check console for errors
- Verify dependencies are loaded

**Purchase fails:**
- Check you have enough cash: `exports['my_money']:GetMoney(source, 'cash')`
- Verify vehicle model exists in config
- Check server console for error messages

**Vehicle doesn't spawn:**
- Check vehicle model is valid GTA V model
- Verify spawn location is not obstructed
- Check client console (F8) for errors

**Vehicle not registered:**
- Verify my_vehicles is running
- Check VerifyPurchase export is being called
- Check server console for authorization errors

## Future Enhancements

- Vehicle categories/filtering
- Test drive functionality
- Trade-in system
- Financing/payment plans
- Dealership reputation
- Multiple dealership locations
- Vehicle customization on purchase

## Support

Check console logs for debugging information. All operations are logged with colored output for easy troubleshooting.

---

**Version:** 1.0.0  
**Author:** BareBones Framework  
**License:** Custom Framework
