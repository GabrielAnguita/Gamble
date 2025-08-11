; This script requires F3 to work
; Function to find WoW window
FindWoWWindow() {
    while (true) {
        try {
            newWowId := WinGetID("World of Warcraft")
            if (newWowId) {
                LogState("World of Warcraft window found: ID " . newWowId)
                return newWowId
            }
        } catch {
            ; WinGetID throws error when window not found, continue trying
        }
        LogState("World of Warcraft window not found, retrying in 1 second...")
        Sleep(1000)
    }
}

; Get the ID of the World of Warcraft window
wowid1 := FindWoWWindow()

#HotIf WinActive("ahk_id " . wowid1)

; Global variables declaration
global isActive := false
global isActionInProgress := false
global lastActionTime := 0
global lastRollDiceTime := 0
global rollDiceCooldown := 5000
global lastAntiIdleTime := 0
global antiIdleMinInterval := 180000  ; 3 minutes in milliseconds
global antiIdleMaxInterval := 294000  ; 4.9 minutes in milliseconds
global nextAntiIdleInterval := 0

; Show startup message
ShowTooltip("Press F3 to activate the script", 5000)

ShowTooltip(message, duration := 2000) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -duration)
}

; Logging function
LogState(message) {
    timeStr := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    OutputDebug("[" . timeStr . "] " . message)
}

; Function to type text slowly like a human
SlowType(text) {
    for char in StrSplit(text, "") {
        Send(char)
        Sleep(Random(100, 300))
    }
}


IsColorSimilar(color1, color2, tolerance := 10) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF

    return (Abs(r1 - r2) <= tolerance) && (Abs(g1 - g2) <= tolerance) && (Abs(b1 - b2) <= tolerance)
}

; Decode gold amount from RGB color using direct hexadecimal
DecodeGoldAmount(color) {
    ; Color is already the hex value we want - just return it directly
    ; Each RGB color directly represents up to 16,777,215 gold
    return color
}

; Configuration variables
ColorX := 729
ColorY := 237
ClickX := 870
ClickY := 264
ColorWarning := 0xDB9C15

TradeWindowColorX := 480
TradeWindowColorY := 428
TradeWindowColor := 0x00FF00
NoTradeWindowColor := 0xFF0000
TradeButtonX := 284
TradeButtonY := 690
DenyTradeButtonX := 410
DenyTradeButtonY := 690

ColorActiveGamble := 0xCC00CC
ActiveCordsX := 1404
ActiveCordsY := 428
RollDiceCordsX := 1470
RollDiceCordsY := 575



; Payout pixel coordinates (defaults)
PayoutPixelX := 478
PayoutPixelY := 460

; Gold input field coordinates (defaults)
GoldInputX := 68
GoldInputY := 234


F3::
{
    global isActive
    isActive := !isActive
    if (isActive) {
        SetTimer(CheckColorAndPerformAction, 1000)
        ShowTooltip("Script activated", 3000)
    }
    else {
        SetTimer(CheckColorAndPerformAction, 0)
        ShowTooltip("Script deactivated", 3000)
    }
}


CheckColorAndPerformAction() {
    global isActive, isActionInProgress, wowid1, lastActionTime, lastRollDiceTime, rollDiceCooldown

    if (!isActive || isActionInProgress || !WinActive("ahk_id " wowid1))
        return

    ; Check for anti-idle movement only during true idle periods
    PerformAntiIdleMovement()

    isActionInProgress := true

    try {
        ; Only check for colors if the 3-second global cooldown has passed
        if (A_TickCount - lastActionTime > 3000) {
            ; Use default coordinates
            adjColor := {x: ColorX, y: ColorY}
            adjClick := {x: ClickX, y: ClickY}
            adjDenyTradeButton := {x: DenyTradeButtonX, y: DenyTradeButtonY}
            adjTradeButton := {x: TradeButtonX, y: TradeButtonY}
            adjActive := {x: ActiveCordsX, y: ActiveCordsY}
            adjTradeWindow := {x: TradeWindowColorX, y: TradeWindowColorY}
            adjPayoutPixel := {x: PayoutPixelX, y: PayoutPixelY}
            adjGoldInput := {x: GoldInputX, y: GoldInputY}

            ; Check for warning color accept Warning after trade accept (highest priority)
            ActualColor := PixelGetColor(adjColor.x, adjColor.y, "RGB")
            if IsColorSimilar(ActualColor, ColorWarning, 15) {
                LogState("State: WARNING_ACCEPT - Color: 0x" . Format("{:06X}", ActualColor) . " Expected: 0x" . Format("{:06X}", ColorWarning))
                PerformAction(adjClick.x, adjClick.y, "AcceptWarning")
            }
            ; Check for red color Deny Trades (second priority)
            else {
                DenyTradeColor := PixelGetColor(adjTradeWindow.x, adjTradeWindow.y, "RGB")
                if IsColorSimilar(DenyTradeColor, NoTradeWindowColor, 20) {
                    LogState("State: DENY_TRADE - Color: 0x" . Format("{:06X}", DenyTradeColor) . " Expected: 0x" . Format("{:06X}", NoTradeWindowColor))
                    PerformAction(adjDenyTradeButton.x, adjDenyTradeButton.y, "DenyTrade")
                }
                ; Check for green color Accept trades(third priority)
                else {
                    TradeWindowActualColor := PixelGetColor(adjTradeWindow.x, adjTradeWindow.y, "RGB")
                    if IsColorSimilar(TradeWindowActualColor, TradeWindowColor, 20) {
                        ; Check if this is a payout situation (green square + encoded amount)
                        LogState("Reading payout pixel at coords: (" . PayoutPixelX . "," . PayoutPixelY . ")")
                        PayoutPixelColor := PixelGetColor(adjPayoutPixel.x, adjPayoutPixel.y, "RGB")
                        payoutAmount := DecodeGoldAmount(PayoutPixelColor)
                        
                        ; Log what AHK reads from the payout pixel
                        LogState("PAYOUT_READ: Coords=(" . adjPayoutPixel.x . "," . adjPayoutPixel.y . "), Hex=0x" . Format("{:06X}", PayoutPixelColor) . ", Decoded=" . payoutAmount . " gold")
                        
                        if (payoutAmount > 0) {
                            LogState("State: PAYOUT_TRADE - Amount: " . payoutAmount . " gold - Pixel Color: 0x" . Format("{:06X}", PayoutPixelColor))
                            ; Enter gold amount in trade window
                            PerformAction(adjGoldInput.x, adjGoldInput.y, "ClickGoldInput")
                            Sleep(500)  ; Wait for field to focus
                            Send("^a")  ; Select all
                            Sleep(Random(300, 500))
                            SlowType(String(Integer(payoutAmount)))
                            Sleep(500)
                            ; Then accept the trade
                            PerformAction(adjTradeButton.x, adjTradeButton.y, "AcceptTrade")
                            Sleep(Random(1500, 2500))  ; Wait longer for trade warning dialog
 			                PerformAction(adjClick.x, adjClick.y, "AcceptWarning")
                        } else {
                            LogState("State: ACCEPT_TRADE - Color: 0x" . Format("{:06X}", TradeWindowActualColor) . " Expected: 0x" . Format("{:06X}", TradeWindowColor))
                            PerformAction(adjTradeButton.x, adjTradeButton.y, "AcceptTrade")
                            Sleep(Random(1500, 2500))  ; Wait longer for trade warning dialog
 			                PerformAction(adjClick.x, adjClick.y, "AcceptWarning")
                        }
                    }
                    ; Check for Active Gamble purple color (fourth priority) to Roll the dice
                    else {
                        ActiveGambleColor := PixelGetColor(adjActive.x, adjActive.y, "RGB")
                        if IsColorSimilar(ActiveGambleColor, ColorActiveGamble, 20) {
                            LogState("State: ACTIVE_GAMBLE - Color: 0x" . Format("{:06X}", ActiveGambleColor) . " Expected: 0x" . Format("{:06X}", ColorActiveGamble))
                            PerformAction(0, 0, "RollDice")  ; Coordinates are not used for RollDice anymore
                        }
                        else {
                            LogState("State: IDLE - Warning: 0x" . Format("{:06X}", ActualColor) . ", Trade: 0x" . Format("{:06X}", TradeWindowActualColor) . ", Active: 0x" . Format("{:06X}", ActiveGambleColor))
                        }
                    }
                }
            }
        }
    }
    catch as err {
        ShowTooltip("Error: " . err.Message, 5000)
    }
    finally {
        isActionInProgress := false
    }
}

PerformAction(x, y, action := "") {
    global lastActionTime, lastRollDiceTime, isActive

    if (!isActive)
        return

    switch action {
        case "RollDice":
            ShowTooltip("Rolling Dice")
            Sleep(Random(1500, 3000))  ; Random delay between 1.5 and 3 seconds
            Send("{6}")  ; Send the '6' key
            lastActionTime := A_TickCount
            lastRollDiceTime := A_TickCount
        case "AcceptWarning", "DenyTrade", "AcceptTrade":
            SmoothMouseMove(x, y)
            Sleep(Random(400, 900))  ; More randomized timing
            if (!isActive)
                return
            ShowTooltip(action)
            Click()
            lastActionTime := A_TickCount
        default:
            SmoothMouseMove(x, y)
            Sleep(Random(50, 150))  ; More randomized timing
            if (!isActive)
                return
            Click()
            lastActionTime := A_TickCount
    }

    Sleep(Random(15, 35))
}

SmoothMouseMove(targetX, targetY) {
    MouseGetPos(&startX, &startY)

    distance := Sqrt((targetX - startX) ** 2 + (targetY - startY) ** 2)

    if (distance < 20) {
        ; Add small random offset even for short distances
        finalX := targetX + Random(-3, 3)
        finalY := targetY + Random(-3, 3)
        MouseMove(finalX, finalY, Random(1, 3))
        return
    }

    ; Variable step count for different movement patterns
    steps := Max(Floor(distance / Random(18, 25)), 4)

    ; Create a simple curved path with one control point
    controlX := startX + (targetX - startX) / 2 + Random(-30, 30)
    controlY := startY + (targetY - startY) / 2 + Random(-30, 30)

    loop steps {
        if (!isActive)
            return
        t := A_Index / steps
        
        ; Simple quadratic bezier curve with random variations
        newX := Round((1 - t) ** 2 * startX + 2 * (1 - t) * t * controlX + t ** 2 * targetX)
        newY := Round((1 - t) ** 2 * startY + 2 * (1 - t) * t * controlY + t ** 2 * targetY)
        
        ; Add small random variations to each point
        newX += Random(-2, 2)
        newY += Random(-2, 2)
        
        MouseMove(newX, newY, Random(1, 2))
        if (A_Index < steps)
            Sleep(Random(2, 5))  ; Randomized timing between movement steps
    }

    ; Final position with small random offset
    finalX := targetX + Random(-4, 4)
    finalY := targetY + Random(-4, 4)
    MouseMove(finalX, finalY, 1)
}

; Anti-idle movement function
PerformAntiIdleMovement() {
    global isActive, lastAntiIdleTime, antiIdleMinInterval, antiIdleMaxInterval, nextAntiIdleInterval
    
    if (!isActive)
        return
    
    ; Calculate next random interval if not set
    if (nextAntiIdleInterval == 0) {
        nextAntiIdleInterval := Random(antiIdleMinInterval, antiIdleMaxInterval)
        lastAntiIdleTime := A_TickCount
        LogState("Anti-idle: Next action in " . Round(nextAntiIdleInterval/1000) . " seconds")
        return
    }
    
    ; Check if it's time for anti-idle action
    if (A_TickCount - lastAntiIdleTime >= nextAntiIdleInterval) {
        LogState("Anti-idle: Performing jump + dance")
        ShowTooltip("Anti-idle: Jump + Dance", 1000)
        
        ; Jump
        Send("{Space}")
        Sleep(Random(500, 1000))
        
        ; Open chat and type /dance slowly with random intervals
        Send("{Enter}")
        Sleep(Random(200, 400))
        
        ; Type /dance slowly
        SlowType("/dance")
        
        Sleep(Random(200, 400))
        Send("{Enter}")
        
        ; Reset timer with new random interval
        lastAntiIdleTime := A_TickCount
        nextAntiIdleInterval := Random(antiIdleMinInterval, antiIdleMaxInterval)
        LogState("Anti-idle: Next action in " . Round(nextAntiIdleInterval/1000) . " seconds")
    }
}

#HotIf
