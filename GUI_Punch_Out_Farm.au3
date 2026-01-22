#cs
;;; GUI Created by MrDomRocks
#ce
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Global $Start, $RefreshButton, $RunInfosGroup, $RunsLabel, $TimeLabel, $Ales, $Form1, $gIdentifyCheckbox, $gSellCheckbox, $gHardModeCheckbox, $ConsoleEdit
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
$CharacterChoiceCombo = GUICtrlCreateCombo("No character selected", 15, 11, 326, 30, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
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
			If GUICtrlRead($gHardModeCheckbox) = $GUI_CHECKED Then
				MsgBox(64, "Hard Mode Advice", "For best performance your character should have:" & @CRLF & _
				"5x Stalwart Insignias" & @CRLF & _
				"Secondary Profession Assassin for Dagger Mastery" & @CRLF & _
				"Thunderfist Brass Knuckles with Sundering or Furious Mods" & @CRLF & _
				"Dagger Handle of Shelter" & @CRLF & _
				"Brawn over Brains Inscription")
			EndIf
	EndSwitch
WEnd
