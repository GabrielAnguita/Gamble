---@class AddonPrivate
local Private = select(2, ...)
local const = Private.constants
local addon = Private.Addon

---@class MessageUtil
local messageUtil = {
    lastReminder = 0
}
Private.MessageUtil = messageUtil

local sayWorthy = {
    ["BET_ACCEPTED"] = true,
    ["CHOICE_PENDING"] = true,
    ["CHOICE_PICKED"] = true,
    ["GAME_WIN"] = true,
    ["GAME_LOSS"] = true,
    ["WON_PAYOUT"] = true,
    ["PENDING_PAYOUT"] = true,
    ["BUSY_WITH_GAME"] = true,
    ["LOYALTY_MIN_BET_NOT_MET"] = true,
    ["UNDER_MIN_BET"] = true,
    ["OVER_MAX_BET"] = true,
    ["JACKPOT_PROGRESS"] = true,
    ["JACKPOT_WIN"] = true,
}

---@param messageType "BET_ACCEPTED"|"CHOICE_PENDING"|"CHOICE_PICKED"|"GAME_WIN"|"GAME_LOSS"|"WON_PAYOUT"|"UNDER_MIN_BET"|"OVER_MAX_BET"|"RULES"|"PERSONAL_STATS"|"NUM_ENTRY"|"NO_FORMAT"|"PENDING_PAYOUT"|"BUSY_WITH_GAME"|"LOYALTY_MIN_BET_NOT_MET"|"RULEJACKPOT"|"JACKPOT_WIN"|"JACKPOT_PROGRESS"
---@param args table
---@param target string|?
function messageUtil:SendMessage(messageType, channel, args, target)
    if messageType == "RULES" then
        for index, partArgs in ipairs(args) do
            self:SendMessage(messageType .. index, channel, partArgs, target)
        end
        return
    end
    if args and type(args) == "table" and args.shouldRepeat then
        for _, partArgs in ipairs(args) do
            self:SendMessage(messageType, channel, partArgs, target)
        end
        return
    end
    if messageType == "CHOICE_PENDING" then
        local curr = GetTime()
        if self.lastReminder + 5 > curr then return end
        self.lastReminder = curr
    end
    local message = const.MESSAGE_TYPES[messageType]
    if not message then
        addon:ThrowError("Invalid message type: " .. tostring(messageType))
        return
    end
    if args and #args > 0 then
        message = message:format(unpack(args))
    end
    if message and message ~= "" then
        SendChatMessage(message, channel, nil, target)
        if sayWorthy[messageType] and addon:GetDatabaseValue("sayPopups") then
            StaticPopupDialogs["SEND_DUPE_IN_SAY"] = {
                text = "Do you want to also send '%s' in /Say",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    SendChatMessage(string.format("@%s: %s", target, message), "SAY")
                end,
                timeout = 10,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("SEND_DUPE_IN_SAY", message)
        end
    else
        addon:ThrowError("Attempted to send empty message for type: " .. tostring(messageType))
    end
end
