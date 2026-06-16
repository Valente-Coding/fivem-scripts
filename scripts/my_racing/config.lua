Config = {}

-- ========================================
-- KEY MAPPINGS  (GTA V control IDs)
-- ========================================
-- E key = INPUT_PICKUP (38)   -> Place checkpoint
-- Y key = INPUT_ENTER  (246)  -> Finalize track (end at last checkpoint)
-- U key = INPUT_REPLAY_RESTART (303 / hash) -> Finalize track (loop to start)
-- Backspace = INPUT_CELLPHONE_CANCEL (194) -> Cancel creation

Config.Keys = {
    PlaceCheckpoint = 38,   -- E
    FinalizeEnd     = 246,  -- Y   (finish at last checkpoint)
    FinalizeLoop    = 303,  -- U   (finish at start)
    Cancel          = 194,  -- Backspace
}

-- ========================================
-- RACE SETTINGS
-- ========================================

-- Checkpoint detection radius (units)
Config.CheckpointRadius = 18.0

-- Minimum checkpoints (including start) to save a track
Config.MinCheckpoints = 3

-- Countdown seconds before race starts
Config.CountdownSeconds = 5

-- Max players per lobby (0 = unlimited)
Config.MaxLobbyPlayers = 0

-- Minimum bet amount (0 = free races allowed)
Config.MinBet = 0

-- Currency used for bets
Config.BetCurrency = 'cash'

-- Admin identifiers (licenses) that can delete any track
Config.AdminLicenses = {
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
}
