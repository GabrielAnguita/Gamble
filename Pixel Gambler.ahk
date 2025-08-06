; This script requires F3 to work
; Get the ID of the World of Warcraft window
wowid1 := WinGetID("World of Warcraft")
if (!wowid1) {
    LogState("World of Warcraft window not found")
    wowid1 := 0
}

#HotIf WinActive("ahk_id " . wowid1)

; Global variables declaration
global isActive := false
global isActionInProgress := false
global lastActionTime := 0
global lastRollDiceTime := 0
global rollDiceCooldown := 5000

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
ClickX := 845
ClickY := 268
ColorWarning := 0xDB9C15

TradeWindowColorX := 478
TradeWindowColorY := 430
TradeWindowColor := 0x00FF00
NoTradeWindowColor := 0xFF0000
TradeButtonX := 286
TradeButtonY := 685
DenyTradeButtonX := 444
DenyTradeButtonY := 161

ColorActiveGamble := 0xCC00CC
ActiveCordsX := 1410
ActiveCordsY := 430
RollDiceCordsX := 1470
RollDiceCordsY := 575


; Calibration cycle variables
calibrationStep := 0
calibrationSteps := ["Warning Accept", "Trade Window", "Active Gamble", "Trade Button", "Deny Trade Button", "Payout Pixel", "Gold Input Field"]

; Payout pixel coordinates (defaults - will be calibrated)
PayoutPixelX := 1650
PayoutPixelY := 400

; Gold input field coordinates (defaults - will be calibrated)
GoldInputX := 400
GoldInputY := 600

; Save calibration to file
SaveCalibration() {
    calibFile := A_ScriptDir . "\calibration.txt"
    content := "ClickX=" . ClickX . "`n"
    content .= "ClickY=" . ClickY . "`n"
    content .= "TradeWindowColorX=" . TradeWindowColorX . "`n"
    content .= "TradeWindowColorY=" . TradeWindowColorY . "`n"
    content .= "ActiveCordsX=" . ActiveCordsX . "`n"
    content .= "ActiveCordsY=" . ActiveCordsY . "`n"
    content .= "TradeButtonX=" . TradeButtonX . "`n"
    content .= "TradeButtonY=" . TradeButtonY . "`n"
    content .= "DenyTradeButtonX=" . DenyTradeButtonX . "`n"
    content .= "DenyTradeButtonY=" . DenyTradeButtonY . "`n"
    content .= "PayoutPixelX=" . PayoutPixelX . "`n"
    content .= "PayoutPixelY=" . PayoutPixelY . "`n"
    content .= "GoldInputX=" . GoldInputX . "`n"
    content .= "GoldInputY=" . GoldInputY
    
    if FileExist(calibFile) {
        FileDelete(calibFile)
    }
    FileAppend(content, calibFile)
    LogState("Calibration saved to " . calibFile)
}

; Load calibration from file
LoadCalibration() {
    global ClickX, ClickY, TradeWindowColorX, TradeWindowColorY
    global ActiveCordsX, ActiveCordsY, TradeButtonX, TradeButtonY
    global DenyTradeButtonX, DenyTradeButtonY, PayoutPixelX, PayoutPixelY
    global GoldInputX, GoldInputY
    
    calibFile := A_ScriptDir . "\calibration.txt"
    
    if FileExist(calibFile) {
        try {
            content := FileRead(calibFile)
            lines := StrSplit(content, "`n")
            
            for line in lines {
                if (line != "") {
                    parts := StrSplit(line, "=")
                    if (parts.Length == 2) {
                        varName := parts[1]
                        value := Integer(parts[2])
                        
                        switch varName {
                            case "ClickX": ClickX := value
                            case "ClickY": ClickY := value
                            case "TradeWindowColorX": TradeWindowColorX := value
                            case "TradeWindowColorY": TradeWindowColorY := value
                            case "ActiveCordsX": ActiveCordsX := value
                            case "ActiveCordsY": ActiveCordsY := value
                            case "TradeButtonX": TradeButtonX := value
                            case "TradeButtonY": TradeButtonY := value
                            case "DenyTradeButtonX": DenyTradeButtonX := value
                            case "DenyTradeButtonY": DenyTradeButtonY := value
                            case "PayoutPixelX": PayoutPixelX := value
                            case "PayoutPixelY": PayoutPixelY := value
                            case "GoldInputX": GoldInputX := value
                            case "GoldInputY": GoldInputY := value
                        }
                    }
                }
            }
            LogState("Calibration loaded from " . calibFile)
        }
        catch {
            LogState("Error loading calibration file")
        }
    } else {
        LogState("No calibration file found, using defaults")
    }
}

; Load calibration on startup
LoadCalibration()

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

F4::  ; Calibration cycle
{
    global calibrationStep, calibrationSteps
    global ClickX, ClickY, TradeWindowColorX, TradeWindowColorY
    global ActiveCordsX, ActiveCordsY, TradeButtonX, TradeButtonY
    global DenyTradeButtonX, DenyTradeButtonY, PayoutPixelX, PayoutPixelY, GoldInputX, GoldInputY
    
    if (calibrationStep == 0) {
        ; Start calibration cycle
        calibrationStep := 1
        ShowTooltip("Calibration started. Hover over " . calibrationSteps[1] . " and press F4 again", 3000)
        LogState("Calibration cycle started - Step 1: " . calibrationSteps[1])
    }
    else {
        ; Calibrate current step  
        MouseGetPos(&mouseX, &mouseY)
        currentColor := PixelGetColor(mouseX, mouseY, "RGB")
        
        if (calibrationStep == 1) {  ; Warning Accept
            ClickX := mouseX
            ClickY := mouseY
            LogState("Calibrated " . calibrationSteps[1] . ": (" . mouseX . "," . mouseY . ") - Color: 0x" . Format("{:06X}", currentColor))
        }
        else if (calibrationStep == 2) {  ; Trade Window
            TradeWindowColorX := mouseX
            TradeWindowColorY := mouseY
            LogState("Calibrated " . calibrationSteps[2] . ": (" . mouseX . "," . mouseY . ") - Color: 0x" . Format("{:06X}", currentColor))
        }
        else if (calibrationStep == 3) {  ; Active Gamble
            ActiveCordsX := mouseX
            ActiveCordsY := mouseY
            LogState("Calibrated " . calibrationSteps[3] . ": (" . mouseX . "," . mouseY . ") - Color: 0x" . Format("{:06X}", currentColor))
            if IsColorSimilar(currentColor, ColorActiveGamble, 20) {
                LogState("*** PURPLE COLOR DETECTED! ***")
            }
        }
        else if (calibrationStep == 4) {  ; Trade Button
            TradeButtonX := mouseX
            TradeButtonY := mouseY
            LogState("Calibrated " . calibrationSteps[4] . ": (" . mouseX . "," . mouseY . ")")
        }
        else if (calibrationStep == 5) {  ; Deny Trade Button
            DenyTradeButtonX := mouseX
            DenyTradeButtonY := mouseY
            LogState("Calibrated " . calibrationSteps[5] . ": (" . mouseX . "," . mouseY . ")")
        }
        else if (calibrationStep == 6) {  ; Payout Pixel
            PayoutPixelX := mouseX
            PayoutPixelY := mouseY
            LogState("Calibrated " . calibrationSteps[6] . ": (" . mouseX . "," . mouseY . ") - Color: 0x" . Format("{:06X}", currentColor))
            
            ; Test decoding the color immediately
            testAmount := DecodeGoldAmount(currentColor)
            LogState("*** PAYOUT PIXEL TEST: Decoded=" . testAmount . " gold from color 0x" . Format("{:06X}", currentColor) . " ***")
        }
        else if (calibrationStep == 7) {  ; Gold Input Field
            GoldInputX := mouseX
            GoldInputY := mouseY
            LogState("Calibrated " . calibrationSteps[7] . ": (" . mouseX . "," . mouseY . ")")
        }
        
        calibrationStep++
        
        if (calibrationStep <= calibrationSteps.Length) {
            ShowTooltip(calibrationSteps[calibrationStep-1] . " calibrated. Hover over " . calibrationSteps[calibrationStep] . " and press F4 again", 3000)
            LogState("Next step: " . calibrationSteps[calibrationStep])
        }
        else {
            calibrationStep := 0
            SaveCalibration()
            ShowTooltip("Calibration complete and saved!", 3000)
            LogState("Calibration cycle completed and saved")
        }
    }
}

CheckColorAndPerformAction() {
    global isActive, isActionInProgress, wowid1, lastActionTime, lastRollDiceTime, rollDiceCooldown

    if (!isActive || isActionInProgress || !WinActive("ahk_id " wowid1))
        return

    isActionInProgress := true

    try {
        ; Only check for colors if the 3-second global cooldown has passed
        if (A_TickCount - lastActionTime > 3000) {
            ; Adjust coordinates based on current resolution
            ; Use direct calibrated coordinates (no scaling)
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
                        LogState("Reading payout pixel at calibrated coords: (" . PayoutPixelX . "," . PayoutPixelY . ")")
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
                            Sleep(200)
                            Send(String(Integer(payoutAmount)))
                            Sleep(500)
                            ; Then accept the trade
                            PerformAction(adjTradeButton.x, adjTradeButton.y, "AcceptTrade")
 			                PerformAction(adjClick.x, adjClick.y, "AcceptWarning")
                        } else {
                            LogState("State: ACCEPT_TRADE - Color: 0x" . Format("{:06X}", TradeWindowActualColor) . " Expected: 0x" . Format("{:06X}", TradeWindowColor))
                            PerformAction(adjTradeButton.x, adjTradeButton.y, "AcceptTrade")
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
            Sleep(Random(300, 700))
            if (!isActive)
                return
            ShowTooltip(action)
            Click()
            lastActionTime := A_TickCount
        default:
            SmoothMouseMove(x, y)
            Sleep(Random(15, 35))
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
        MouseMove(targetX, targetY, 0)
        return
    }

    steps := Max(Floor(distance / 20), 3)

    controlX := startX + (targetX - startX) / 2 + Random(-10, 10)
    controlY := startY + (targetY - startY) / 2 + Random(-10, 10)

    loop steps {
        if (!isActive)
            return
        t := A_Index / steps
        newX := Round((1 - t) ** 2 * startX + 2 * (1 - t) * t * controlX + t ** 2 * targetX)
        newY := Round((1 - t) ** 2 * startY + 2 * (1 - t) * t * controlY + t ** 2 * targetY)
        MouseMove(newX, newY, 0)
        if (A_Index < steps)
            Sleep(1)
    }

    MouseMove(targetX, targetY, 0)
}
#HotIf
