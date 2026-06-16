Config = {}

-- Key to attach/detach vehicle (default: K)
Config.AttachKey = 311 -- K key

-- Maximum distance to detect a flatbed truck (in meters)
Config.FlatbedDetectDistance = 10.0

-- Maximum distance to detect a vehicle to load onto the flatbed
Config.VehicleDetectDistance = 12.0

-- Flatbed truck model hashes
-- Add any flatbed model you want to support
Config.FlatbedModels = {
    "flatbed",
    "rollback",  -- Slamvan flatbed variant
    "trflat",    -- Trailer flatbed
}

-- Offset where the vehicle is placed on the flatbed (x, y relative to flatbed)
-- z is calculated dynamically per vehicle so all cars sit on the bed surface
Config.AttachOffset = {
    x = 0.0,
    y = -1.95,
}

-- Height of the flatbed bed surface relative to the flatbed's origin
-- This is the z level where the vehicle's wheels should rest
Config.FlatbedBedHeight = 1.23

-- Rotation of the attached vehicle relative to the flatbed
Config.AttachRotation = {
    x = 0.0,
    y = 0.0,
    z = 0.0,
}

-- Draw 3D help text above the flatbed
Config.Draw3DText = true

-- Notification messages
Config.Messages = {
    attached = "~g~Vehicle attached to flatbed!",
    detached = "~y~Vehicle detached from flatbed.",
    noVehicle = "~r~No vehicle nearby to load.",
    tooFar = "~r~You are too far from a flatbed.",
    inVehicle = "~r~Exit your vehicle first!",
    alreadyLoaded = "~y~This flatbed already has a vehicle loaded.",
}
