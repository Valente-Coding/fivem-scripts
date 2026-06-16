Config = {}

-- Dividend payment schedule (game time)
Config.DividendSchedule = {
    {h = 9},   -- 9:00 AM
    {h = 17}   -- 5:00 PM
}

-- Price update interval in milliseconds (5 minutes)
Config.PriceUpdateInterval = 300000

-- Price history retention (number of records to keep per company)
Config.MaxHistoryRecords = 120

-- Sector color coding for UI
Config.SectorColors = {
    ['Finance'] = '#ffd700',
    ['Technology'] = '#00d4ff',
    ['Retail'] = '#ff9500',
    ['Food & Beverage'] = '#00ff88',
    ['Automotive'] = '#ff4757',
    ['Security'] = '#a4a4a4'
}

-- Default companies (GTA V Lore)
Config.DefaultCompanies = {
    -- Finance Sector
    {
        name = 'Maze Bank',
        ticker = 'MAZ',
        sector = 'Finance',
        starting_price = 150,
        max_shares = 100000,
        dividend_per_share = 3,
        volatility = 3,
        rubberband_strength = 0.15
    },
    {
        name = 'Fleeca',
        ticker = 'FLE',
        sector = 'Finance',
        starting_price = 95,
        max_shares = 80000,
        dividend_per_share = 2,
        volatility = 4,
        rubberband_strength = 0.18
    },
    {
        name = 'Gruppe6',
        ticker = 'GRU6',
        sector = 'Finance',
        starting_price = 120,
        max_shares = 60000,
        dividend_per_share = 2,
        volatility = 3,
        rubberband_strength = 0.16
    },

    -- Technology Sector
    {
        name = 'Lifeinvader',
        ticker = 'LFI',
        sector = 'Technology',
        starting_price = 200,
        max_shares = 120000,
        dividend_per_share = 2,
        volatility = 8,
        rubberband_strength = 0.25
    },
    {
        name = 'Eyefind',
        ticker = 'EYE',
        sector = 'Technology',
        starting_price = 175,
        max_shares = 90000,
        dividend_per_share = 2,
        volatility = 7,
        rubberband_strength = 0.22
    },

    -- Retail Sector
    {
        name = 'Ammu-Nation',
        ticker = 'AMU',
        sector = 'Retail',
        starting_price = 85,
        max_shares = 70000,
        dividend_per_share = 1,
        volatility = 5,
        rubberband_strength = 0.20
    },
    {
        name = '24/7 Stores',
        ticker = 'TFS',
        sector = 'Retail',
        starting_price = 65,
        max_shares = 100000,
        dividend_per_share = 1,
        volatility = 4,
        rubberband_strength = 0.30
    },

    -- Food & Beverage Sector
    {
        name = 'eCola',
        ticker = 'ECL',
        sector = 'Food & Beverage',
        starting_price = 110,
        max_shares = 95000,
        dividend_per_share = 3,
        volatility = 5,
        rubberband_strength = 0.35
    },
    {
        name = 'Cluckin Bell',
        ticker = 'CLU',
        sector = 'Food & Beverage',
        starting_price = 75,
        max_shares = 85000,
        dividend_per_share = 1,
        volatility = 5,
        rubberband_strength = 0.28
    },
    {
        name = 'Burger Shot',
        ticker = 'BS',
        sector = 'Food & Beverage',
        starting_price = 70,
        max_shares = 90000,
        dividend_per_share = 1,
        volatility = 4,
        rubberband_strength = 0.32
    },

    -- Automotive Sector
    {
        name = 'Los Santos Customs',
        ticker = 'LSC',
        sector = 'Automotive',
        starting_price = 130,
        max_shares = 65000,
        dividend_per_share = 2,
        volatility = 6,
        rubberband_strength = 0.24
    },

    -- Security Sector
    {
        name = 'Merryweather',
        ticker = 'MER',
        sector = 'Security',
        starting_price = 165,
        max_shares = 75000,
        dividend_per_share = 3,
        volatility = 6,
        rubberband_strength = 0.20
    }
}
