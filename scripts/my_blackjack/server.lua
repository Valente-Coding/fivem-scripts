-- ============================================================
-- my_blackjack | server.lua
-- Server-authoritative multiplayer blackjack
-- ============================================================

-- Game state
local table_state = {
    phase = 'idle',       -- idle / betting / dealing / playing / dealer / payout
    players = {},         -- { [seat] = { source, name, bet, hand, status, handValue } }
    dealer = { hand = {}, handValue = 0 },
    shoe = {},
    currentSeat = nil,
    phaseTimer = 0,
    roundId = 0
}

local seated = {}  -- { [source] = seatIndex }

-- ============================================================
-- DECK / SHOE HELPERS
-- ============================================================

local suits = { 'hearts', 'diamonds', 'clubs', 'spades' }
local ranks = { '2','3','4','5','6','7','8','9','10','jack','queen','king','ace' }

local function BuildShoe()
    local shoe = {}
    for d = 1, Config.DeckCount do
        for _, suit in ipairs(suits) do
            for _, rank in ipairs(ranks) do
                shoe[#shoe+1] = { rank = rank, suit = suit }
            end
        end
    end
    -- Fisher-Yates shuffle
    for i = #shoe, 2, -1 do
        local j = math.random(1, i)
        shoe[i], shoe[j] = shoe[j], shoe[i]
    end
    return shoe
end

local function DrawCard()
    if #table_state.shoe < 20 then
        table_state.shoe = BuildShoe()
    end
    local card = table_state.shoe[#table_state.shoe]
    table_state.shoe[#table_state.shoe] = nil
    return card
end

local function CardValue(card)
    if card.rank == 'ace' then return 11
    elseif card.rank == 'king' or card.rank == 'queen' or card.rank == 'jack' then return 10
    else return tonumber(card.rank) end
end

local function HandValue(hand)
    local total = 0
    local aces = 0
    for _, card in ipairs(hand) do
        local v = CardValue(card)
        if v == 11 then aces = aces + 1 end
        total = total + v
    end
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end
    return total
end

local function CardToImage(card)
    return card.rank .. '_of_' .. card.suit .. '.png'
end

-- ============================================================
-- GET PLAYER NAME
-- ============================================================

local function GetPlayerDisplayName(src)
    return GetPlayerName(src) or ('Player ' .. src)
end

-- ============================================================
-- BROADCAST STATE TO ALL SEATED PLAYERS
-- ============================================================

local function BroadcastState()
    -- Build a sanitised state for clients
    local clientState = {
        phase = table_state.phase,
        currentSeat = table_state.currentSeat,
        phaseTimer = table_state.phaseTimer,
        roundId = table_state.roundId,
        dealer = {
            hand = {},
            handValue = 0
        },
        players = {}
    }

    -- Dealer cards: hide hole card during 'dealing' and 'playing' phases
    for i, card in ipairs(table_state.dealer.hand) do
        if (table_state.phase == 'dealing' or table_state.phase == 'playing') and i == 2 then
            clientState.dealer.hand[i] = { rank = 'hidden', suit = 'hidden', image = 'card_back.png' }
        else
            clientState.dealer.hand[i] = { rank = card.rank, suit = card.suit, image = CardToImage(card) }
        end
    end

    -- Dealer value: hide if hole card hidden
    if (table_state.phase == 'dealing' or table_state.phase == 'playing') and #table_state.dealer.hand >= 2 then
        clientState.dealer.handValue = CardValue(table_state.dealer.hand[1])
    else
        clientState.dealer.handValue = HandValue(table_state.dealer.hand)
    end

    -- Player data (sequential array with explicit seat field for JS compatibility)
    for seat = 1, Config.MaxPlayers do
        local p = table_state.players[seat]
        if p then
            local cards = {}
            for _, card in ipairs(p.hand) do
                cards[#cards+1] = { rank = card.rank, suit = card.suit, image = CardToImage(card) }
            end
            clientState.players[#clientState.players+1] = {
                seat = seat,
                name = p.name,
                bet = p.bet,
                hand = cards,
                handValue = HandValue(p.hand),
                status = p.status,
                source = p.source
            }
        end
    end

    -- Send to each seated player
    for src, _ in pairs(seated) do
        TriggerClientEvent('my_blackjack:updateState', src, clientState, seated[src])
        -- Also send their current balance
        local balance = exports['my_money']:GetMoney(src, 'cash')
        TriggerClientEvent('my_blackjack:updateBalance', src, balance or 0)
    end
end

-- ============================================================
-- SEAT MANAGEMENT
-- ============================================================

RegisterNetEvent('my_blackjack:joinTable')
AddEventHandler('my_blackjack:joinTable', function()
    local src = source

    -- Already seated?
    if seated[src] then
        TriggerClientEvent('my_blackjack:notify', src, 'You are already at the table.')
        return
    end

    -- Find open seat
    local openSeat = nil
    for s = 1, Config.MaxPlayers do
        if not table_state.players[s] then
            openSeat = s
            break
        end
    end

    if not openSeat then
        TriggerClientEvent('my_blackjack:notify', src, 'Table is full.')
        return
    end

    -- Seat the player
    table_state.players[openSeat] = {
        source = src,
        name = GetPlayerDisplayName(src),
        bet = 0,
        hand = {},
        status = 'waiting',  -- waiting for next round
        handValue = 0
    }
    seated[src] = openSeat

    TriggerClientEvent('my_blackjack:seated', src, openSeat)
    TriggerClientEvent('my_blackjack:notify', src, 'Seated at position ' .. openSeat .. '.')

    -- If idle, start betting phase
    if table_state.phase == 'idle' then
        StartBettingPhase()
    end

    BroadcastState()
end)

RegisterNetEvent('my_blackjack:leaveTable')
AddEventHandler('my_blackjack:leaveTable', function()
    local src = source
    RemovePlayer(src)
end)

function RemovePlayer(src)
    local seat = seated[src]
    if not seat then return end

    -- If they had a bet and the round is active, they forfeit
    table_state.players[seat] = nil
    seated[src] = nil

    TriggerClientEvent('my_blackjack:left', src)

    -- If no players left, reset
    local hasPlayers = false
    for _, _ in pairs(seated) do
        hasPlayers = true
        break
    end

    if not hasPlayers then
        ResetTable()
    else
        -- If it was their turn, advance
        if table_state.phase == 'playing' and table_state.currentSeat == seat then
            AdvanceTurn()
        end
        BroadcastState()
    end
end

AddEventHandler('playerDropped', function()
    local src = source
    if seated[src] then
        RemovePlayer(src)
    end
end)

-- ============================================================
-- BETTING PHASE
-- ============================================================

function StartBettingPhase()
    table_state.phase = 'betting'
    table_state.roundId = table_state.roundId + 1
    table_state.phaseTimer = Config.BettingTime
    table_state.dealer = { hand = {}, handValue = 0 }

    -- Reset all seated players for new round
    for seat, p in pairs(table_state.players) do
        p.bet = 0
        p.hand = {}
        p.status = 'betting'
        p.handValue = 0
    end

    BroadcastState()

    -- Timer countdown
    local roundId = table_state.roundId
    CreateThread(function()
        for t = Config.BettingTime, 0, -1 do
            if table_state.roundId ~= roundId then return end
            if table_state.phase ~= 'betting' then return end
            table_state.phaseTimer = t
            BroadcastState()
            Wait(1000)
        end
        -- Time's up — remove players who didn't bet, then deal
        if table_state.phase == 'betting' and table_state.roundId == roundId then
            EndBettingPhase()
        end
    end)
end

RegisterNetEvent('my_blackjack:placeBet')
AddEventHandler('my_blackjack:placeBet', function(amount)
    local src = source
    local seat = seated[src]
    if not seat then return end
    if table_state.phase ~= 'betting' then return end

    local p = table_state.players[seat]
    if not p or p.status ~= 'betting' then return end

    amount = tonumber(amount)
    if not amount or amount < Config.MinBet or amount > Config.MaxBet then
        TriggerClientEvent('my_blackjack:notify', src, 'Bet must be between $' .. Config.MinBet .. ' and $' .. Config.MaxBet)
        return
    end

    -- Check balance
    local balance = exports['my_money']:GetMoney(src, 'cash')
    if balance < amount then
        TriggerClientEvent('my_blackjack:notify', src, 'Not enough cash.')
        return
    end

    -- Take the money
    local success = exports['my_money']:RemoveMoney(src, 'cash', amount)
    if not success then
        TriggerClientEvent('my_blackjack:notify', src, 'Transaction failed.')
        return
    end

    p.bet = amount
    p.status = 'bet_placed'
    TriggerClientEvent('my_blackjack:notify', src, 'Bet placed: $' .. amount)

    -- Check if all players have bet
    local allBet = true
    for _, pl in pairs(table_state.players) do
        if pl.status == 'betting' then
            allBet = false
            break
        end
    end

    if allBet then
        EndBettingPhase()
    else
        BroadcastState()
    end
end)

function EndBettingPhase()
    -- Remove players who didn't bet
    local toRemove = {}
    for seat, p in pairs(table_state.players) do
        if p.status == 'betting' or p.bet == 0 then
            toRemove[#toRemove+1] = { seat = seat, src = p.source }
        end
    end
    for _, r in ipairs(toRemove) do
        table_state.players[r.seat] = nil
        seated[r.src] = nil
        TriggerClientEvent('my_blackjack:notify', r.src, 'You did not place a bet.')
        TriggerClientEvent('my_blackjack:left', r.src)
    end

    -- Anyone left?
    local hasPlayers = false
    for _, _ in pairs(table_state.players) do
        hasPlayers = true
        break
    end

    if not hasPlayers then
        ResetTable()
        return
    end

    -- Build shoe if needed
    if #table_state.shoe < 52 then
        table_state.shoe = BuildShoe()
    end

    DealCards()
end

-- ============================================================
-- DEALING PHASE
-- ============================================================

function DealCards()
    table_state.phase = 'dealing'

    -- Deal 2 cards to each player and dealer
    for round = 1, 2 do
        for seat = 1, Config.MaxPlayers do
            local p = table_state.players[seat]
            if p then
                p.hand[#p.hand+1] = DrawCard()
            end
        end
        table_state.dealer.hand[#table_state.dealer.hand+1] = DrawCard()
    end

    -- Calculate values
    for _, p in pairs(table_state.players) do
        p.handValue = HandValue(p.hand)
        if p.handValue == 21 then
            p.status = 'blackjack'
        else
            p.status = 'playing'
        end
    end
    table_state.dealer.handValue = HandValue(table_state.dealer.hand)

    BroadcastState()

    -- Brief pause then start play phase
    CreateThread(function()
        Wait(2000)
        StartPlayPhase()
    end)
end

-- ============================================================
-- PLAY PHASE (player turns)
-- ============================================================

function StartPlayPhase()
    table_state.phase = 'playing'

    -- Find first active player
    table_state.currentSeat = FindNextPlayingSeat(0)

    if not table_state.currentSeat then
        -- All blackjack or bust?
        DealerPhase()
        return
    end

    StartTurnTimer()
    BroadcastState()
end

function FindNextPlayingSeat(afterSeat)
    for s = afterSeat + 1, Config.MaxPlayers do
        local p = table_state.players[s]
        if p and p.status == 'playing' then
            return s
        end
    end
    return nil
end

function StartTurnTimer()
    local roundId = table_state.roundId
    local seat = table_state.currentSeat
    table_state.phaseTimer = Config.TurnTime

    CreateThread(function()
        for t = Config.TurnTime, 0, -1 do
            if table_state.roundId ~= roundId then return end
            if table_state.currentSeat ~= seat then return end
            if table_state.phase ~= 'playing' then return end
            table_state.phaseTimer = t
            -- Only broadcast every 5 seconds or at key moments to reduce traffic
            if t % 5 == 0 or t <= 5 then
                BroadcastState()
            end
            Wait(1000)
        end
        -- Time ran out — auto stand
        if table_state.phase == 'playing' and table_state.currentSeat == seat and table_state.roundId == roundId then
            local p = table_state.players[seat]
            if p and p.status == 'playing' then
                p.status = 'stand'
                TriggerClientEvent('my_blackjack:notify', p.source, 'Time expired — auto stand.')
                AdvanceTurn()
            end
        end
    end)
end

function AdvanceTurn()
    local nextSeat = FindNextPlayingSeat(table_state.currentSeat or 0)
    if nextSeat then
        table_state.currentSeat = nextSeat
        StartTurnTimer()
        BroadcastState()
    else
        table_state.currentSeat = nil
        DealerPhase()
    end
end

-- ============================================================
-- PLAYER ACTIONS
-- ============================================================

RegisterNetEvent('my_blackjack:hit')
AddEventHandler('my_blackjack:hit', function()
    local src = source
    local seat = seated[src]
    if not seat or table_state.phase ~= 'playing' or table_state.currentSeat ~= seat then return end

    local p = table_state.players[seat]
    if not p or p.status ~= 'playing' then return end

    p.hand[#p.hand+1] = DrawCard()
    p.handValue = HandValue(p.hand)

    if p.handValue > 21 then
        p.status = 'bust'
        TriggerClientEvent('my_blackjack:notify', src, 'Bust! You went over 21.')
        AdvanceTurn()
    elseif p.handValue == 21 then
        p.status = 'stand'
        TriggerClientEvent('my_blackjack:notify', src, '21! Standing automatically.')
        AdvanceTurn()
    else
        BroadcastState()
    end
end)

RegisterNetEvent('my_blackjack:stand')
AddEventHandler('my_blackjack:stand', function()
    local src = source
    local seat = seated[src]
    if not seat or table_state.phase ~= 'playing' or table_state.currentSeat ~= seat then return end

    local p = table_state.players[seat]
    if not p or p.status ~= 'playing' then return end

    p.status = 'stand'
    AdvanceTurn()
end)

RegisterNetEvent('my_blackjack:doubleDown')
AddEventHandler('my_blackjack:doubleDown', function()
    local src = source
    local seat = seated[src]
    if not seat or table_state.phase ~= 'playing' or table_state.currentSeat ~= seat then return end

    local p = table_state.players[seat]
    if not p or p.status ~= 'playing' then return end
    if #p.hand ~= 2 then
        TriggerClientEvent('my_blackjack:notify', src, 'Can only double down on first two cards.')
        return
    end

    -- Check balance for additional bet
    local balance = exports['my_money']:GetMoney(src, 'cash')
    if balance < p.bet then
        TriggerClientEvent('my_blackjack:notify', src, 'Not enough cash to double down.')
        return
    end

    local success = exports['my_money']:RemoveMoney(src, 'cash', p.bet)
    if not success then
        TriggerClientEvent('my_blackjack:notify', src, 'Transaction failed.')
        return
    end

    p.bet = p.bet * 2

    -- Draw exactly one card
    p.hand[#p.hand+1] = DrawCard()
    p.handValue = HandValue(p.hand)

    if p.handValue > 21 then
        p.status = 'bust'
        TriggerClientEvent('my_blackjack:notify', src, 'Bust on double down!')
    else
        p.status = 'stand'
        TriggerClientEvent('my_blackjack:notify', src, 'Double down! Standing with ' .. p.handValue)
    end

    AdvanceTurn()
end)

-- ============================================================
-- DEALER PHASE
-- ============================================================

function DealerPhase()
    table_state.phase = 'dealer'
    table_state.currentSeat = nil
    BroadcastState()

    -- Check if any players are still in (not bust)
    local anyActive = false
    for _, p in pairs(table_state.players) do
        if p.status == 'stand' or p.status == 'blackjack' then
            anyActive = true
            break
        end
    end

    if not anyActive then
        -- Everyone busted, skip dealer play
        CreateThread(function()
            Wait(1500)
            PayoutPhase()
        end)
        return
    end

    -- Dealer draws (with delays for animation)
    CreateThread(function()
        Wait(1000)
        -- Reveal hole card
        table_state.dealer.handValue = HandValue(table_state.dealer.hand)
        BroadcastState()
        Wait(1500)

        -- Dealer hits on 16 and below, stands on 17+
        while HandValue(table_state.dealer.hand) < 17 do
            table_state.dealer.hand[#table_state.dealer.hand+1] = DrawCard()
            table_state.dealer.handValue = HandValue(table_state.dealer.hand)
            BroadcastState()
            Wait(1500)
        end

        table_state.dealer.handValue = HandValue(table_state.dealer.hand)
        BroadcastState()
        Wait(1000)

        PayoutPhase()
    end)
end

-- ============================================================
-- PAYOUT
-- ============================================================

function PayoutPhase()
    table_state.phase = 'payout'
    local dealerValue = HandValue(table_state.dealer.hand)
    local dealerBust = dealerValue > 21

    for seat, p in pairs(table_state.players) do
        local payout = 0
        local result = ''

        if p.status == 'blackjack' then
            -- Check if dealer also has blackjack
            if #table_state.dealer.hand == 2 and dealerValue == 21 then
                payout = p.bet  -- push
                result = 'Push (both blackjack) — $' .. payout .. ' returned.'
            else
                payout = p.bet + math.floor(p.bet * Config.BlackjackPayout)
                result = 'Blackjack! You win $' .. (payout - p.bet) .. '!'
            end
        elseif p.status == 'bust' then
            payout = 0
            result = 'Bust. You lose $' .. p.bet .. '.'
        elseif p.status == 'stand' then
            local playerValue = HandValue(p.hand)
            if dealerBust then
                payout = p.bet * 2
                result = 'Dealer bust! You win $' .. p.bet .. '!'
            elseif playerValue > dealerValue then
                payout = p.bet * 2
                result = 'You win $' .. p.bet .. '!'
            elseif playerValue == dealerValue then
                payout = p.bet
                result = 'Push — $' .. payout .. ' returned.'
            else
                payout = 0
                result = 'Dealer wins. You lose $' .. p.bet .. '.'
            end
        end

        -- Pay out
        if payout > 0 then
            exports['my_money']:AddMoney(p.source, 'cash', payout)
        end

        p.status = result
        TriggerClientEvent('my_blackjack:notify', p.source, result)
    end

    BroadcastState()

    -- Wait then start next round or go idle
    CreateThread(function()
        Wait(6000)

        -- Check if anyone is still seated
        local hasPlayers = false
        for _, _ in pairs(seated) do
            hasPlayers = true
            break
        end

        if hasPlayers then
            StartBettingPhase()
        else
            ResetTable()
        end
    end)
end

-- ============================================================
-- RESET
-- ============================================================

function ResetTable()
    table_state.phase = 'idle'
    table_state.currentSeat = nil
    table_state.phaseTimer = 0
    table_state.dealer = { hand = {}, handValue = 0 }
    -- Keep seated players but reset their state
    for seat, p in pairs(table_state.players) do
        p.bet = 0
        p.hand = {}
        p.status = 'waiting'
        p.handValue = 0
    end
    BroadcastState()
end

-- ============================================================
-- INIT
-- ============================================================

CreateThread(function()
    math.randomseed(os.time())
    table_state.shoe = BuildShoe()
    print('^2[my_blackjack]^7 Blackjack table ready.')
end)
