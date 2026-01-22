#cs
;;; GUI Created by MrDomRocks
#ce
#RequireAdmin
#include "../../API/_GwAu3.au3"
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Global $Start, $RefreshButton, $RunInfosGroup, $RunsLabel, $TimeLabel, $Ales, $Form1, $gIdentifyCheckbox, $gSellCheckbox, $gHardModeCheckbox, $ConsoleEdit
Global $BotRunning = False
Global $RunCount = 0
Global $AleCount = 0
Global $TimerInit = 0
#Region ### START Koda GUI section ### Form=C:\Users\mrdom\Desktop\GUI.kxf
; Increased width to 530 to fit controls
$Form1 = GUICreate("Punch Out", 530, 239, 727, 595)
GUISetCursor(2)
GUISetFont(8, 400, 0, "Calibri")
; Moved Start button to X=440
$Start = GUICtrlCreateButton("Start", 440, 11, 75, 25)
$StatusBar1 = _GUICtrlStatusBar_Create($Form1)
Dim $StatusBar1_PartsWidth[3] = [100, 225, 1]
_GUICtrlStatusBar_SetParts($StatusBar1, $StatusBar1_PartsWidth)
_GUICtrlStatusBar_SetText($StatusBar1, "Punch Out Farm", 0)
_GUICtrlStatusBar_SetText($StatusBar1, "By MrDomRocks", 1)
_GUICtrlStatusBar_SetText($StatusBar1, "With thanks to the GwAu3 Community", 2)
_GUICtrlStatusBar_SetBkColor($StatusBar1, 0xB4B4B4)
_GUICtrlStatusBar_SetMinHeight($StatusBar1, 34)
$CharacterChoiceCombo = GUICtrlCreateCombo("", 15, 11, 326, 30, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
GUICtrlSetData(-1, Scanner_GetLoggedCharNames())
; Moved Refresh button to X=350 to avoid clash with Combo
$RefreshButton = GUICtrlCreateButton("Refresh", 350, 11, 75, 25)
$RunInfosGroup = GUICtrlCreateGroup("Infos", 12, 41, 136, 105)
$RunsLabel = GUICtrlCreateLabel("Runs: 0", 17, 66, 125, 16)
$TimeLabel = GUICtrlCreateLabel("Time: 0", 17, 91, 125, 16)
$Ales = GUICtrlCreateLabel("Ales: 0", 16, 116, 125, 16)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$gIdentifyCheckbox = GUICtrlCreateCheckbox("Auto Identify", 12, 152, 85, 20)
$gSellCheckbox = GUICtrlCreateCheckbox("Auto Sell", 100, 152, 70, 20)
$gHardModeCheckbox = GUICtrlCreateCheckbox("Hard Mode", 12, 176, 85, 20)

; Widened Console to 320 to fill new space
$ConsoleEdit = GUICtrlCreateEdit("", 192, 45, 320, 145, BitOR($ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $ES_WANTRETURN, $WS_VSCROLL, $ES_READONLY))
GUICtrlSetData(-1, "")
GUICtrlSetColor(-1, 0xFFFFFF)
GUICtrlSetBkColor(-1, 0x000000)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $Start
			If $BotRunning Then
				$BotRunning = False
				GUICtrlSetData($Start, "Start")
				GUICtrlSetData($ConsoleEdit, "Bot Paused" & @CRLF, 1)
			Else
				If GUICtrlRead($gHardModeCheckbox) = $GUI_CHECKED Then
					MsgBox(64, "Hard Mode Advice", "For best performance your character should have:" & @CRLF & _
					"5x Stalwart Insignias" & @CRLF & _
					"Secondary Profession Assassin for Dagger Mastery" & @CRLF & _
					"Thunderfist Brass Knuckles with Sundering or Furious Mods" & @CRLF & _
					"Dagger Handle of Shelter" & @CRLF & _
					"Brawn over Brains Inscription")
				EndIf
				
				; Initialize Core with selected character
				Local $sCharName = GUICtrlRead($CharacterChoiceCombo)
				If $sCharName <> "" And $sCharName <> "No character selected" Then
					If Core_Initialize($sCharName, True) Then
						GUICtrlSetData($ConsoleEdit, "Attached to: " & $sCharName & @CRLF, 1)
						$BotRunning = True
						$TimerInit = TimerInit() ; Start Timer
						GUICtrlSetData($Start, "Pause")
						GUICtrlSetData($ConsoleEdit, "Bot Started" & @CRLF, 1)
					Else
						GUICtrlSetData($ConsoleEdit, "Failed to attach to: " & $sCharName & @CRLF, 1)
					EndIf
				Else
					MsgBox(48, "Error", "Please select a character first.")
				EndIf
			EndIf

		Case $RefreshButton
			GUICtrlSetData($CharacterChoiceCombo, "|" & Scanner_GetLoggedCharNames()) ; Reload
			
	EndSwitch
	
	If $BotRunning Then
		If GUICtrlRead($gIdentifyCheckbox) = $GUI_CHECKED Then
			IdentifyCycle()
		EndIf
		If GUICtrlRead($gSellCheckbox) = $GUI_CHECKED Then
			SellCycle()
		EndIf
		
		; Update Stats
		Local $iDiff = TimerDiff($TimerInit)
		Local $iHours = Floor($iDiff / 3600000)
		Local $iMins = Floor(Mod($iDiff, 3600000) / 60000)
		Local $iSecs = Floor(Mod($iDiff, 60000) / 1000)
		
		GUICtrlSetData($TimeLabel, StringFormat("Time: %02d:%02d:%02d", $iHours, $iMins, $iSecs))
		GUICtrlSetData($RunsLabel, "Runs: " & $RunCount)
		GUICtrlSetData($Ales, "Ales: " & $AleCount)
		
		Sleep(100)
	EndIf
WEnd

Func Out($TEXT)
    Local $TEXTLEN = StringLen($TEXT)
    Local $CONSOLELEN = _GUICtrlEdit_GetTextLen($ConsoleEdit)
    If $TEXTLEN + $CONSOLELEN > 30000 Then GUICtrlSetData($ConsoleEdit, StringRight(_GUICtrlEdit_GetText($ConsoleEdit), 30000 - $TEXTLEN - 1000))
    _GUICtrlEdit_AppendText($ConsoleEdit, @CRLF & $TEXT)
    _GUICtrlEdit_Scroll($ConsoleEdit, 1)
EndFunc

Func IdentifyCycle()
    Local $l_a_Bags = [1, 2, 3, 4] ; Backpack, Belt Pouch, Bag 1, Bag 2
    For $bagIndex In $l_a_Bags
        Local $l_p_Bag = Item_GetBagPtr($bagIndex)
        If $l_p_Bag = 0 Then ContinueLoop
        Local $l_i_Slots = Item_GetBagInfo($l_p_Bag, 'Slots')
        For $slot = 1 To $l_i_Slots
            Local $l_p_Item = Item_GetItemBySlot($bagIndex, $slot)
            If $l_p_Item = 0 Then ContinueLoop
            
            Local $l_b_Identified = Item_GetItemInfoByPtr($l_p_Item, 'IsIdentified')
            If Not $l_b_Identified Then
                Out("Identifying item in Bag " & $bagIndex & " Slot " & $slot)
                Item_IdentifyItem($l_p_Item)
                Sleep(500) ; Wait a bit
            EndIf
        Next
    Next
EndFunc

Func SellCycle()
    Local $l_a_Bags = [1, 2, 3, 4] 
    For $bagIndex In $l_a_Bags
        Local $l_p_Bag = Item_GetBagPtr($bagIndex)
        If $l_p_Bag = 0 Then ContinueLoop
        Local $l_i_Slots = Item_GetBagInfo($l_p_Bag, 'Slots')
        For $slot = 1 To $l_i_Slots
            Local $l_p_Item = Item_GetItemBySlot($bagIndex, $slot)
            If $l_p_Item = 0 Then ContinueLoop
            
            Local $l_b_Identified = Item_GetItemInfoByPtr($l_p_Item, 'IsIdentified')
            Local $l_i_Rarity = Item_GetItemInfoByPtr($l_p_Item, 'Rarity')
            
            ; Only sell White, Blue, Purple
            If $l_b_Identified And ($l_i_Rarity = $GC_I_RARITY_WHITE Or $l_i_Rarity = $GC_I_RARITY_BLUE Or $l_i_Rarity = $GC_I_RARITY_PURPLE) Then
                 ; Exclude Kits and Dyes (simplistic check)
                 Local $l_i_Type = Item_GetItemInfoByPtr($l_p_Item, 'ItemType')
                 If $l_i_Type <> $GC_I_TYPE_KIT And $l_i_Type <> $GC_I_TYPE_DYE Then
                    Out("Selling item in Bag " & $bagIndex & " Slot " & $slot)
                    Merchant_SellItem($l_p_Item)
                    Sleep(500)
                 EndIf
            EndIf
        Next
    Next
EndFunc
