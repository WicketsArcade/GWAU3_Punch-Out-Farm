#cs
;;; Punch Out Farmer = Created by MrDomRocks
; You run in Normal Mode
: Punch and Run
#ce
#RequireAdmin

#Region Includes
#include "..\API\_GwAu3.au3"
#include "AddOns\GwAu3_AddOns_Punch_Out_Farm.au3"
#include "GUI\GUI_Punch_Out_Farm.au3"
#include "..\API\SmartCast\_UtilityAI.au3"
#include "..\API\Modules\Cmd\GwAu3_Cmd_NPC.au3"
#include "..\API\Modules\Cmd\GwAu3_Cmd_Dialog.au3"
#include "..\API\Pathfinding\Pathfinder_Movements.au3"
#EndRegion Includes

#Region Global Constants & Variables
; === Bot Settings ===
Global Const $BotTitle = "Punch Out Farmer by MrDomRocks"
Global $ProcessID = ""
Global $BotRunning = False
Global $Bot_Core_Initialized = False
Global $g_s_MainCharName = ""

; === Map & Quest Constants ===
Global Const $MAP_ID_GUUNAR = 644
Global Const $FRONIS_QUEST = 856
Global Const $MAP_ID_FRONIS = 704

; === Dialog IDs ===
Global Const $Dialog_Intro = 0x835803
Global Const $Dialog_AcceptQuest = 0x835801
Global Const $Dialog_Enter = 0x85
Global Const $Dialog_Reward = 0x835807

; === Skill & Stats ===
Global Const $maxAllowdEnergy = 120
Global Const $intAdrenaline[7] = [0, 0, 0, 100, 250, 175, 0]
Global $g_i_Runs = 0
Global $g_i_Fails = 0
Global $g_i_Ales = 0
Global $g_i_StartTime = TimerInit()
Global $g_h_EditText = $ConsoleEdit ; Link to GUI control

; === Initialization ===
Opt("GUIOnEventMode", True)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

; Populate Character Combo on Load
Local $sLogedChars = Scanner_GetLoggedCharNames()
If $sLogedChars <> "" Then
    GUICtrlSetData($CharacterChoiceCombo, $sLogedChars, StringSplit($sLogedChars, "|")[1])
EndIf
#EndRegion Global Constants & Variables

#Region Event Handlers
; =================================================================================================
; GUI Event Handlers
; Functions related to GUI interaction (Start/Stop, Refresh, Close)
; =================================================================================================

GUISetOnEvent($GUI_EVENT_CLOSE, "CloseBot", $Form1)
GUICtrlSetOnEvent($Start, "ToggleBot")
GUICtrlSetOnEvent($RefreshButton, "RefreshCharacters")

Func RefreshCharacters()
    Local $sLogedChars = Scanner_GetLoggedCharNames()
    If $sLogedChars <> "" Then
        GUICtrlSetData($CharacterChoiceCombo, "|" & $sLogedChars, StringSplit($sLogedChars, "|")[1])
        Update("Character list refreshed")
    Else
        Update("No characters found")
    EndIf
EndFunc

Func ToggleBot()
    If Not $BotRunning Then
        Local $sChar = GUICtrlRead($CharacterChoiceCombo)
        If $sChar = "No character selected" Or $sChar = "" Then
            MsgBox(0, "Error", "Please select a character first!")
            Return
        EndIf

        If Not $Bot_Core_Initialized Then
            If Not Core_Initialize($sChar) Then
                MsgBox(0, "Error", "Failed to initialize bot core with character: " & $sChar)
                Return
            EndIf
            $Bot_Core_Initialized = True
            $g_s_MainCharName = $sChar
        EndIf

        $BotRunning = True
        GUICtrlSetData($Start, "Pause")
        Update("BotStarted")
    Else
        $BotRunning = False
        GUICtrlSetData($Start, "Start")
        Update("Paused")
    EndIf
EndFunc

Func CloseBot()
    Exit
EndFunc
#EndRegion Event Handlers

#Region Main Loop
; =================================================================================================
; Main Logic Loop
; Handles state switching between Outpost and Instance
; =================================================================================================

While 1
    If $BotRunning Then
        MainBotLoop()
    EndIf
    Sleep(100) ; Reduce CPU usage
WEnd

Func MainBotLoop()
    UpdateGUIStats()

    Local $l_i_CurrentMapID = Map_GetCharacterInfo("MapID")

    Switch $l_i_CurrentMapID
        Case $MAP_ID_GUUNAR
            HandleOutpost()
        Case $MAP_ID_FRONIS
            HandleInstance()
        Case Else
            Update("Traveling to Gunnar's Hold")
            RndTravel($MAP_ID_GUUNAR)
            Sleep(5000)
    EndSwitch
EndFunc
#EndRegion Main Loop

#Region Outpost Logic
; =================================================================================================
; Outpost Logic
; Handles preparation, quest acceptance, and reward claiming
; =================================================================================================

Func HandleOutpost()
    Update("Preparing for Quest")
    
    ; 1. Leave Party
    Party_KickAllHeroes()
    
    ; 2. Equip Item
    Item_EquipItem(68)
    
    ; 3. Move to Kilroy
    Local $l_f_KilroyX = 17341.00
    Local $l_f_KilroyY = -4796.00
    
    If Agent_GetDistanceToXY($l_f_KilroyX, $l_f_KilroyY) > 250 Then
        Pathfinder_MoveTo($l_f_KilroyX, $l_f_KilroyY)
        Sleep(500)
    EndIf
    
    ; 4. Handle Quest/Dialog Logic
    If Not EnterInstance($FRONIS_QUEST) Then
        Update("Failed to enter instance, retrying...")
        Sleep(1000)
    Else
        ; Wait for map change
        Update("Waiting for instance entry...")
        Local $timer = TimerInit()
        While Map_GetCharacterInfo("MapID") = $MAP_ID_GUUNAR
            Sleep(500)
            If TimerDiff($timer) > 15000 Then ExitLoop
        WEnd
    EndIf
EndFunc

Func EnterInstance($QuestID)
    Local $l_f_KilroyX = 17341.00
    Local $l_f_KilroyY = -4796.00
    
    Local $KilroyID = GetNearestNPC($l_f_KilroyX, $l_f_KilroyY)
    If $KilroyID = 0 Then
        Update("Kilroy not found!")
        Return False
    EndIf
    
    Agent_ChangeTarget($KilroyID)
    Agent_GoNPC($KilroyID)
    Sleep(1000)
    
    ; 1. Intro Dialog
    Game_Dialog($Dialog_Intro)
    Sleep(500)
    
    ; 2. Accept Quest
    Game_Dialog($Dialog_AcceptQuest)
    Update("Quest Accepted")
    Sleep(500)
    
    ; 3. Enter Instance
    Game_Dialog($Dialog_Enter)
    Sleep(1000)
    
    Return True
EndFunc

Func ClaimReward()
    Local $l_f_KilroyX = 17341.00
    Local $l_f_KilroyY = -4796.00
    
    Local $KilroyID = GetNearestNPC($l_f_KilroyX, $l_f_KilroyY)
    If $KilroyID <> 0 Then
        Agent_ChangeTarget($KilroyID)
        Agent_GoNPC($KilroyID)
        Sleep(1000)
        ; Claim Reward Dialog
        Game_Dialog($Dialog_Reward) 
        Sleep(1000)
    EndIf
EndFunc
#EndRegion Outpost Logic

#Region Instance Logic
; =================================================================================================
; Instance Logic
; Handles the main farming sequence inside Fronis Irontoe's Lair
; =================================================================================================

Func HandleInstance()
    RunPunchOutSequence()
EndFunc

Func RunPunchOutSequence()
    ; Move to safe start position
    Pathfinder_MoveTo(-16919.56, -13485.12)
    Sleep(500)

    ; Cache skills ONCE at start
    UAI_CacheSkillBar()

    ; Fight initial spawns
    Update("Fighting at start position")
    Brawling_ClearArea(1500)
    
    ; Cache skills again before first combat waypoint
    UAI_CacheSkillBar()

    Update("Fronis Instance Combat Loop Started")
    Local $aWaypoints[10][2] = [ _
        [-15115.72, -15375.61], _
        [-11299.54, -16402.40], _
        [-7284.53, -16235.58], _
        [-4397.42, -16123.15], _
        [-1385.20, -14400.23], _
        [505.33, -14073.99], _
        [2959.12, -15991.76], _
        [5740.82, -15543.48], _
        [7157.02, -15755.44], _
        [12249.79, -16291.74]]
        
    For $i = 0 To UBound($aWaypoints) - 1
        Local $tX = $aWaypoints[$i][0]
        Local $tY = $aWaypoints[$i][1]
        
      ; Update("Moving to waypoint " & $i + 1)
        
        ; Log Movement Start
        FileWriteLine(@ScriptDir & "\MovementLog.txt", "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] START Move to WP " & $i + 1 & " (" & $tX & ", " & $tY & ") | Current: " & Agent_GetAgentInfo(-2, "X") & ", " & Agent_GetAgentInfo(-2, "Y"))
        
        ; Move with automated combat check
        Local $timer = TimerInit()
        Local $bReached = False
        
        While True
            ; Check if we are close enough (Manual check to fix false timeouts)
            Local $fDist = Agent_GetDistanceToXY($tX, $tY)
            If $fDist < 150 Then
                $bReached = True
                ExitLoop
            EndIf
            
            ; Move command
            Pathfinder_MoveTo($tX, $tY)
            
            ; Timeout check
            If TimerDiff($timer) > 25000 Then 
                Update("Failed to reach waypoint " & $i + 1 & " - Timeout")
                FileWriteLine(@ScriptDir & "\MovementLog.txt", "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] FAILED Move to WP " & $i + 1 & " - Timeout. Stuck at: " & Agent_GetAgentInfo(-2, "X") & ", " & Agent_GetAgentInfo(-2, "Y"))
                ExitLoop
            EndIf
            
            ; Log intermediate position
            FileWriteLine(@ScriptDir & "\MovementLog.txt", "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] MOVING... Current: " & Agent_GetAgentInfo(-2, "X") & ", " & Agent_GetAgentInfo(-2, "Y"))
            
            ; Explicit combat check during movement
            If GetNearestEnemyToCoords(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), 1000) <> 0 Then
                ; Attempt to use Skill 1 (Sprint/Block) while moving if available
                If Brawling_IsRecharged(1) Then
                    Brawling_UseSkillEx(1, -2, 200)
                EndIf
                
                Brawling_ClearArea(1500)
            EndIf
            
            ; Pick up loot while moving
            PickUpLoot()
            
            Sleep(100)
        WEnd
        
        ; Clear area at waypoint
        ; Update("Fighting at waypoint " & $i + 1)
        FileWriteLine(@ScriptDir & "\MovementLog.txt", "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] REACHED WP " & $i + 1 & ". Clearing area...")
        Brawling_ClearArea(1500)
        
        ; Update("Looting at waypoint " & $i + 1)
        PickUpLoot()
        
        ; Pause based on health
        Local $fHP = Agent_GetAgentInfo(-2, "HP")
        If $fHP < 1.0 Then
             Update("Resting until full health...")
             Do
                 Sleep(500)
                 $fHP = Agent_GetAgentInfo(-2, "HP")
             Until $fHP >= 0.95 ; Wait until 95%+ health
             Update("Health recovered. Resuming...")
        EndIf
    Next
    
    Sleep(100)
    Update("Opening final chest")
    
    ; Move to and interact with final signpost
    Local $l_i_SignpostID = GetNearestSignpostToCoords(13275, -16039)
    If $l_i_SignpostID <> 0 Then
        Update("Interacting with final signpost")
        Agent_ChangeTarget($l_i_SignpostID)
        Pathfinder_MoveTo(Agent_GetAgentInfo($l_i_SignpostID, "X"), Agent_GetAgentInfo($l_i_SignpostID, "Y"))
        Sleep(500)
        
        ; Keep trying to open chest until it's open (Gadget State changes)
        Local $l_timerChest = TimerInit()
        Do
            Agent_GoNPC($l_i_SignpostID)
            Sleep(500)
            Game_Interact($l_i_SignpostID)
            Sleep(1000)
        Until TimerDiff($l_timerChest) > 5000 
    Else
        Update("Signpost not found! Checking alternative location...")
    EndIf
    
    Sleep(2000)
    Update("Fronis Instance Completed")
    Update("Picking up ale")
    
    ; Ensure Ale is picked up
    Local $l_timerLoot = TimerInit()
    Do
        PickUpLoot()
        Sleep(500)
    Until TimerDiff($l_timerLoot) > 5000 ; Try for 5 seconds max
    
    $g_i_Runs += 1
    $g_i_Ales += 1 ; Increment count (Assuming success)
    UpdateGUIStats()
    
    Update("Run complete. Resigning...")
    RndTravel($MAP_ID_GUUNAR)
    Sleep(5000)
    
    ; === Post-Run Logic in Outpost ===
    ; Wait to load back into Gunnar's Hold
    If Map_WaitMapIsLoaded() Then
        Update("Returned to Outpost. Claiming Reward...")
        ClaimReward()
        Update("Quest Completed")
        
        Update("Changing District...")
        Local $currentDistrict = Map_GetCharacterInfo("District")
        Local $newDistrict = ($currentDistrict = 1) ? 2 : 1 ; Toggle between Dist 1 and 2
        Map_MoveMap($MAP_ID_GUUNAR, Map_GetCharacterInfo("Region"), $newDistrict, Map_GetCharacterInfo("Language"))
        Map_WaitMapIsLoaded()
        
        Update("Restarting Loop...")
    EndIf
EndFunc
#EndRegion Instance Logic

#Region Helper Functions
; =================================================================================================
; Helper Functions
; General utility functions for finding targets, updating GUI, etc.
; =================================================================================================

Func Update($sText)
    _GUICtrlStatusBar_SetText($StatusBar1, $sText, 0)
    Out($sText)
EndFunc

Func UpdateGUIStats()
    GUICtrlSetData($RunsLabel, "Runs: " & $g_i_Runs)
    GUICtrlSetData($FailuresLabel, "Failures: " & $g_i_Fails)
    GUICtrlSetData($Ales, "Ales: " & $g_i_Ales)
    
    Local $iDiff = TimerDiff($g_i_StartTime)
    Local $iHours = Floor($iDiff / 3600000)
    Local $iMins = Floor(Mod($iDiff, 3600000) / 60000)
    Local $iSecs = Floor(Mod($iDiff, 60000) / 1000)
    GUICtrlSetData($TimeLabel, StringFormat("Time: %02d:%02d:%02d", $iHours, $iMins, $iSecs))
EndFunc

; Finds the nearest Gadget (Chest/Signpost) to specific coords
Func GetNearestSignpostToCoords($a_f_X, $a_f_Y)
    Local $l_i_MaxAgents = Agent_GetMaxAgents()
    Local $l_i_BestID = 0
    Local $l_f_MinDist = 500 ; Max range to search
    
    For $i = 1 To $l_i_MaxAgents
        Local $l_p_Agent = Agent_GetAgentPtr($i)
        If $l_p_Agent = 0 Then ContinueLoop
        
        ; Filter for Gadgets (0x200) only
        Local $l_i_Type = Agent_GetAgentInfo($i, "Type")
        If $l_i_Type <> 0x200 Then ContinueLoop
        
        Local $l_f_AgentX = Agent_GetAgentInfo($i, "X")
        Local $l_f_AgentY = Agent_GetAgentInfo($i, "Y")
        
        Local $l_f_Dist = Sqrt(($a_f_X - $l_f_AgentX)^2 + ($a_f_Y - $l_f_AgentY)^2)
        
        If $l_f_Dist < $l_f_MinDist Then
            $l_f_MinDist = $l_f_Dist
            $l_i_BestID = $i
        EndIf
    Next
    
    Return $l_i_BestID
EndFunc

; Finds the nearest Enemy (Allegiance 0x3)
Func GetNearestEnemyToCoords($a_f_X, $a_f_Y, $a_f_Range)
    Local $l_i_MaxAgents = Agent_GetMaxAgents()
    Local $l_i_BestID = 0
    Local $l_f_MinDist = $a_f_Range
    
    For $i = 1 To $l_i_MaxAgents
        Local $l_p_Agent = Agent_GetAgentPtr($i)
        If $l_p_Agent = 0 Then ContinueLoop
        
        If Agent_GetAgentInfo($i, "HP") <= 0 Then ContinueLoop
        If Agent_GetAgentInfo($i, "Allegiance") <> 0x3 Then ContinueLoop ; Enemy = 0x3
        
        Local $l_f_AgentX = Agent_GetAgentInfo($i, "X")
        Local $l_f_AgentY = Agent_GetAgentInfo($i, "Y")
        
        Local $l_f_Dist = Sqrt(($a_f_X - $l_f_AgentX)^2 + ($a_f_Y - $l_f_AgentY)^2)
        
        If $l_f_Dist < $l_f_MinDist Then
            $l_f_MinDist = $l_f_Dist
            $l_i_BestID = $i
        EndIf
    Next
    
    Return $l_i_BestID
EndFunc

; Finds the nearest Friendly NPC (Allegiance 0x6)
Func GetNearestNPC($a_f_X, $a_f_Y)
    Local $l_i_MaxAgents = Agent_GetMaxAgents()
    Local $l_i_BestID = 0
    Local $l_f_MinDist = 500
    
    For $i = 1 To $l_i_MaxAgents
        Local $l_p_Agent = Agent_GetAgentPtr($i)
        If $l_p_Agent = 0 Then ContinueLoop
        
        Local $l_i_Allegiance = Agent_GetAgentInfo($i, "Allegiance")
        If $l_i_Allegiance <> 0x6 Then ContinueLoop
        
        Local $l_f_AgentX = Agent_GetAgentInfo($i, "X")
        Local $l_f_AgentY = Agent_GetAgentInfo($i, "Y")
        
        Local $l_f_Dist = Sqrt(($a_f_X - $l_f_AgentX)^2 + ($a_f_Y - $l_f_AgentY)^2)
        
        If $l_f_Dist < $l_f_MinDist Then
            $l_f_MinDist = $l_f_Dist
            $l_i_BestID = $i
        EndIf
    Next
    
    Return $l_i_BestID
EndFunc
#EndRegion Helper Functions
