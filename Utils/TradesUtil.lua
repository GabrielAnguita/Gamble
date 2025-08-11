---@class AddonPrivate
local Private = select(2, ...)
local const = Private.constants
local addon = Private.Addon
local msg = Private.MessageUtil

---@class TradesUtil
local tradesUtil = {}
Private.TradesUtil = tradesUtil

local MAX_BET_MULTIPLIER = 10000
local MIN_BET_MULTIPLIER = 10000

---@return TradeInfo
function tradesUtil:GetTrade()
    return addon:GetDatabaseValue("activeGame")
end

---@param tradeInfo TradeInfo
function tradesUtil:SaveTrade(tradeInfo)
    addon:SetDatabaseValue("activeGame", tradeInfo)
    msg:SendMessage("BET_ACCEPTED", "WHISPER", { C_CurrencyInfo.GetCoinText(tradeInfo.bet) }, tradeInfo.name)
end

---@class TradeInfo
---@field guid string
---@field name string
---@field bet number
---@field payout number
---@field pendingPayout number
---@field consecutiveWins number
---@field lastBetAmount number
---@field newBetDuringPayout boolean
local tempTrade = {}
local tradeTimer

local function initializeTrade(unitGUID, unitName, pendingPayout)
    return {
        guid = unitGUID or "",
        name = unitName,
        bet = 0,
        pendingPayout = pendingPayout,
        payout = 0,
        consecutiveWins = 0,
        lastBetAmount = 0,
        newBetDuringPayout = false
    }
end

local function getTradeMoneyAmount(isPlayer)
    if isPlayer then
        if GetPlayerTradeMoney then
            return tonumber(GetPlayerTradeMoney()) or 0
        end
    else
        if GetTargetTradeMoney then
            return tonumber(GetTargetTradeMoney()) or 0
        end
    end
    return 0
end

local function updatePendingPayout(playerMoney, tradeAccepted)
    if tempTrade.pendingPayout and playerMoney > 0 and tradeAccepted then
        local remainingPayout = math.max(0, tempTrade.pendingPayout - playerMoney)
        addon:SetDatabaseValue("pendingPayout." .. tempTrade.guid, remainingPayout)
        tempTrade.pendingPayout = remainingPayout
        tempTrade.newBetDuringPayout = (tempTrade.bet > 0)
    end
end

local function validateBet(bet, maxBet, minBet, playerAcceptedTrade)
    if bet > maxBet and playerAcceptedTrade then
        Private.UI:ShowRedSquare()
        msg:SendMessage("OVER_MAX_BET", "WHISPER",
            { C_CurrencyInfo.GetCoinText(bet), C_CurrencyInfo.GetCoinText(maxBet) },
            tempTrade.name)
        return 0
    elseif bet < minBet and bet > 0 and playerAcceptedTrade then
        Private.UI:ShowRedSquare()
        msg:SendMessage("UNDER_MIN_BET", "WHISPER",
            { C_CurrencyInfo.GetCoinText(bet), C_CurrencyInfo.GetCoinText(minBet) },
            tempTrade.name)
        return 0
    elseif bet > 0 and playerAcceptedTrade then
        Private.UI:ShowGreenSquare()
    end
    return math.min(bet, maxBet)
end

local function addLoyaltyBonus()
    if addon:GetDatabaseValue("loyalty") then
        local loyaltyPercent = addon:GetDatabaseValue("loyaltyPercent")
        local loyaltyBonus = math.floor((tempTrade.bet * loyaltyPercent) / 100)
        local loyaltyValues = addon:GetDatabaseValue("loyaltyAmount")
        local previousLoyalty = loyaltyValues[tempTrade.guid] or 0
        addon:SetDatabaseValue("loyaltyAmount." .. tempTrade.guid, previousLoyalty + loyaltyBonus)
    end
end

local function newTrade()
    local unitGUID = UnitGUID("npc")
    local unitName, unitRealm = GetUnitName("npc", true)
    if unitRealm then
        unitName = string.format("%s-%s", unitName, unitRealm)
    end
    local pendingPayouts = addon:GetDatabaseValue("pendingPayout")
    local pendingPayout = pendingPayouts[unitGUID]
    pendingPayout = pendingPayout and pendingPayout > 0 and pendingPayout or nil
    Private.UI:UpdatePendingPayoutText(pendingPayout, unitGUID)

    if pendingPayout then
        -- SOLUCIÓN FINAL: Notificar al usuario para que pague manualmente.
        print("|cffFFFF00Gamble Addon: Payout Due|r")
        Private.UI:ShowGreenSquare() -- Indicador visual de que hay un pago pendiente.
    else
        Private.UI:HideSquares()
    end

    tempTrade = initializeTrade(unitGUID, unitName, pendingPayout)
    --  Antitroll
    if tradeTimer then
        tradeTimer:Cancel()
    end
    tradeTimer = C_Timer.NewTimer(math.random(30, 35), function()
        if TradeFrame and TradeFrame:IsShown() then
            Private.UI:ShowRedSquare()
            msg:SendMessage("NO_BET_DETECTED", "WHISPER", {}, tempTrade.name)
        end
    end)
    return unitName
end

local function updateTrade(_, event, playerAccepted, targetAccepted)
    local bet = getTradeMoneyAmount(false)  -- dinero del objetivo
    local playerMoney = getTradeMoneyAmount(true)  -- dinero del jugador
    tempTrade.payout = playerMoney

    local maxBet = addon:GetDatabaseValue("maxBet") * MAX_BET_MULTIPLIER
    local minBet = addon:GetDatabaseValue("minBet") * MIN_BET_MULTIPLIER
    local tradeAccepted = (event == "TRADE_ACCEPT_UPDATE" and playerAccepted == 1 and targetAccepted == 1)
    local playerAcceptedTrade = (event == "TRADE_ACCEPT_UPDATE" and targetAccepted == 1)

    updatePendingPayout(playerMoney, tradeAccepted)
    tempTrade.bet = validateBet(bet, maxBet, minBet, playerAcceptedTrade)

    if tempTrade.bet > 0 and tradeAccepted then
        if tradeTimer then
            tradeTimer:Cancel()
        end
        addLoyaltyBonus()
        tradesUtil:SaveTrade(tempTrade)
    end
end

local function completeTrade(_, _, _, message)
    if message == ERR_TRADE_COMPLETE then
        if tradeTimer then
            tradeTimer:Cancel()
        end
        if tempTrade.pendingPayout and not tempTrade.newBetDuringPayout then
            local remainingPayout = math.max(0, tempTrade.pendingPayout - tempTrade.payout)
            addon:SetDatabaseValue("pendingPayout." .. tempTrade.guid, remainingPayout)
        end

        tempTrade = initializeTrade(tempTrade.guid, tempTrade.name, nil)
    end
end

addon:RegisterEvent("TRADE_SHOW", "TradesUtil.lua", newTrade)
addon:RegisterEvent("TRADE_MONEY_CHANGED", "TradesUtil.lua", updateTrade)
addon:RegisterEvent("TRADE_ACCEPT_UPDATE", "TradesUtil.lua", updateTrade)
addon:RegisterEvent("UI_INFO_MESSAGE", "TradesUtil.lua", completeTrade)
