Config = {}

-- ============================================================
-- OIL DRAIN
-- ============================================================

-- Maximum oil level (full tank)
Config.MaxOil = 100.0

-- Oil units lost per kilometer driven
-- At 0.15 per km, a full tank lasts ~667 km
Config.OilDrainPerKm = 0.15

-- How often (ms) to check distance for drain (matches mileage loop)
Config.DrainCheckInterval = 500

-- How often (ms) to sync oil level to server
Config.OilSyncInterval = 10000

-- ============================================================
-- WARNING THRESHOLDS
-- ============================================================

-- Below this, player gets a low oil warning
Config.LowOilThreshold = 25.0

-- At or below this, vehicle enters faulty state
Config.CriticalOilThreshold = 0.0

-- ============================================================
-- FAULT EFFECTS (when oil is at 0)
-- ============================================================

-- Maximum speed in km/h when vehicle is faulty
Config.FaultySpeedCap = 15.0

-- When oil hits 0, engine health drops to a random percentage of max
-- (1000.0) within this range. Also triggers GTA's built-in engine smoke
-- (below 300 = white smoke from hood, below 100 = black smoke).
Config.OilDepletedEngineHealthMin = 0
Config.OilDepletedEngineHealthMax = 40

-- Engine power reduction when faulty (fraction of normal, 0.3 = 30% power)
-- These prevent wheelspin by cutting torque alongside the speed cap.
Config.FaultyPowerMultiplier  = 0.3
Config.FaultyTorqueMultiplier = 0.3

-- Chance per tick (every ~2s) that the engine chugs / misfires
Config.StallChance = 0.30

-- Number of rapid on-off chugs per misfire event
Config.ChugCountMin = 2
Config.ChugCountMax = 5

-- Duration (ms) the engine stays OFF during each chug
Config.ChugOffMin = 150
Config.ChugOffMax = 400

-- Duration (ms) the engine stays ON between chugs
Config.ChugOnMin  = 100
Config.ChugOnMax  = 300

-- How often (ms) to check for stall rolls while faulty
Config.FaultTickInterval = 2000

-- Distance to vehicle for using oil bottle
Config.UseDistance = 5.0

-- Duration of oil refill animation (ms)
Config.RefillAnimDuration = 5000
