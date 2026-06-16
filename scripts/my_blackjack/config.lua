Config = {}

-- Table location (x, y, z, heading)
Config.TableLocation = vector3(1151.2383, 267.2954, -51.8408)
Config.TableHeading = 222.4417

-- Interaction
Config.InteractDistance = 3.0   -- radius players can join from
Config.MarkerDistance = 15.0    -- distance to start drawing marker

-- Game settings
Config.MaxPlayers = 5           -- max players per table
Config.MinBet = 50
Config.MaxBet = 10000
Config.BettingTime = 15         -- seconds for betting phase
Config.TurnTime = 30            -- seconds per player turn
Config.DeckCount = 6            -- number of decks in the shoe
Config.BlackjackPayout = 1.5    -- 3:2 payout for blackjack

-- Blip
Config.Blip = {
    sprite = 682,
    color = 5,
    scale = 0.8,
    name = "Blackjack Table"
}

-- Marker (drawn on ground near table)
Config.Marker = {
    type = 25,
    scale = vector3(1.0, 1.0, 0.5),
    color = {r = 0, g = 200, b = 0, a = 100}
}
