﻿;==============================================================
; ALTRun - An effective launcher for Windows.
; https://github.com/zhugecaomao/ALTRun
;==============================================================
#Requires AutoHotkey v1.1
#NoEnv                                                                  ; Recommended for performance and compatibility.
#SingleInstance, Force
#NoTrayIcon
#Persistent

FileEncoding, UTF-8
SetWorkingDir %A_ScriptDir%                                             ; Ensures a consistent starting directory.

;=============================================================
; 声明全局变量,定义配置文件设置
;=============================================================
Global g_IniFile    := A_ScriptDir "\" A_ComputerName ".ini"
    ,  g_LogFile    := A_Temp "\ALTRun.log"
    ,  SEC_CONFIG   := "Config"
    ,  SEC_GUI      := "Gui"
    ,  SEC_DFTCMD   := "DefaultCommand"
    ,  SEC_USERCMD  := "UserCommand"
    ,  SEC_FALLBACK := "FallbackCommand"
    ,  SEC_HOTKEY   := "Hotkey"
    ,  SEC_HISTORY  := "History"
    ,  SEC_INDEX    := "Index"

, KEYLIST_CONFIG := "AutoStartup,EnableSendTo,InStartMenu,IndexDir,IndexFileType,IndexExclude,SearchFullPath,ShowIcon,KeepInputText,HideOnDeactivate,AlwaysOnTop,SaveHistory,HistorySize,isLogging,AutoRank,EscClearInput,SendToGetLnk,Editor,TCPath,Everything,RunCount,EnableScheduler,ShutdownTime,AutoSwitchDir,FileManager,DialogWin,ExcludeWin"
, KEYLIST_GUI    := "HideTitle,ShowTrayIcon,HideCol2,LVGrid,DisplayRows,Col3Width,Col4Width,FontName,FontSize,FontColor,WinWidth,EditHeight,ListHeight,CtrlColor,WinColor,BackgroundPicture"
, KEYLIST_HOTKEY := "GlobalHotkey1,GlobalHotkey2,Hotkey1,Trigger1,Hotkey2,Trigger2,Hotkey3,Trigger3,RunCmdAlt,EnableCapsLockIME,TotalCMDDir,ExplorerDir"

, g_AutoStartup := 1                        ; 是否添加快捷方式到开机启动
, g_EnableSendTo := 1                       ; 是否创建“发送到”菜单
, g_InStartMenu := 1                        ; 是否添加快捷方式到开始菜单中
, g_IndexDir := "A_ProgramsCommon|A_StartMenu" ; 搜索的目录,可以使用 全路径 或以 A_ 开头的AHK变量, 以 "|" 分隔, 路径可包含空格, 无需加引号
, g_IndexFileType := "*.lnk|*.exe"          ; 搜索的文件类型, 以 "|" 分隔
, g_IndexExclude := "Uninstall *"           ; 排除的文件,正则表达式
, g_SearchFullPath := 0                     ; 搜索完整路径,否则只搜文件名
, g_ShowIcon := 1                           ; Show Icon in File ListView
, g_KeepInputText := 1                      ; 窗口隐藏时不清空编辑框内容
, g_TCPath := A_Space                       ; TotalCommander 路径,如果为空则使用资源管理器打开
, g_HideOnDeactivate := 1                   ; 窗口失去焦点后关闭窗口
, g_AlwaysOnTop := 1                        ; 窗口置顶显示
, g_SaveHistory := 1                        ; 记录历史
, g_HistorySize := 15                       ; 记录历史的数量
, g_RunCount := 0                           ; Record command execution times
, g_isLogging := 1                          ; Enable log record
, g_AutoRank := 1                           ; 自动根据使用频率调节顺序
, g_EscClearInput := 1                      ; 输入 Esc 时,如果输入框有内容则清空,无内容才关闭窗口
, g_Editor := A_Space                       ; 用来打开配置文件的编辑器,推荐Notepad2,默认为资源管理器关联的编辑器,可以右键->属性->打开方式修改
, g_SendToGetLnk := 1                       ; 如果使用发送到菜单发送的文件是 .lnk 的快捷方式,从文件读取路径后添加目标文件
, g_Everything := A_Space                   ; Everything.exe 文件路径
, g_EnableScheduler := 0                    ; Task Scheduler for PC auto shutdown
, g_ShutdownTime := "22:30"                 ; Set timing for PC auto shutdown
, g_AutoSwitchDir := 0
, g_FileManager := "ahk_class CabinetWClass|ahk_class TTOTAL_CMD"
, g_DialogWin := "ahk_class #32770"         ; Class name of the Dialog Box which Listary Switch Dir will take effect
, g_ExcludeWin := "ahk_class SysListView32|ahk_exe Explorer.exe,|AutoCAD LT" ; Exclude those windows that not want Listary Switch Dir take effect
, g_HideTitle := 0                          ; 隐藏标题栏
, g_ShowTrayIcon := 1                       ; 是否显示托盘图标
, g_DisplayRows := 9                        ; 在列表中显示的行数,如果超过9行,定位到该行的快捷键将无效
, g_Col3Width := 415                        ; 在列表中第三列的宽度
, g_Col4Width := 360                        ; 在列表中第四列的宽度
, g_HideCol2 := 0                           ; 隐藏第二列,即显示 文件、功能 的一列 `n如果隐藏, 第二列的空间会分给第三列
, g_LVGrid := 0                             ; Show Grid in ListView
, g_FontName := "Segoe UI"                  ; Font Name (eg. Default, Segoe UI, Microsoft Yahei)
, g_FontSize := 10                          ; Font Size, Default is 10
, g_FontColor := "Default"                  ; Font Color, (eg. cRed, cFFFFAA, cDefault)
, g_WinWidth := 900
, g_EditHeight := 24
, g_ListHeight := 260                       ; Command List Height
, g_CtrlColor := "Default"
, g_WinColor := "Default"
, g_BackgroundPicture := "Default"
, g_BGPicture                               ; Real path of the BackgroundPicture
, g_Hints := ["It's better to show me by press hotkey (Default is ALT + Space)"
    , "ALT + Space = Show / Hide window", "Alt + F4 = Exit"
    , "Esc = Clear Input / Close window", "Enter = Run current command"
    , "Alt + No. = Run specific command", "Start with + = New Command"
    , "Ctrl + No. = Select specific command"
    , "F1 = Show Help", "F2 = Open Setting Config window"
    , "F3 = Edit config file (ALTRun.ini) directly"
    , "Arrow Up / Down = Move to Previous / Next command"
    , "Ctrl+H = Show command history", "Ctrl+Q = Reload ALTRun"
    , "Ctrl+'+' = Increase rank of current command"
    , "Ctrl+'-' = Decrease rank of current command"
    , "Ctrl+I = Reindex file search database"
    , "Ctrl+D = Open current command dir with TC / File Explorer"
    , "Command priority (rank) will auto adjust based on frequency"
    , "Start with space = Search by Everything"]

, g_Hotkey1 := "^s", g_Trigger1 := "Everything"
, g_Hotkey2 := "^p", g_Trigger2 := "RunPTTools"
, g_Hotkey3 := "", g_Trigger3 := ""
, g_GlobalHotkey1 := "!Space", g_GlobalHotkey2 := "!R"
, g_TotalCMDDir   := "^g"    , g_ExplorerDir       := "^e"              ; Hotkey for Listary quick-switch dir
, g_RunCmdAlt := 0           , g_EnableCapsLockIME := 0
, OneDrive, OneDriveConsumer , OneDriveCommercial                       ; Environment Variables (Due to #NoEnv, some need to get from EnvGet)
EnvGet, OneDrive, OneDrive                                              ; OneDrive (Default)
EnvGet, OneDriveConsumer, OneDriveConsumer                              ; OneDrive for Personal
EnvGet, OneDriveCommercial, OneDriveCommercial                          ; OneDrive for Business

;=============================================================
; 声明全局变量
; 当前输入命令的参数,数组,为了方便没有添加 g_ 前缀
;=============================================================
global Arg                                    ; 用来调用管道的完整参数（所有列）
, FullPipeArg                                 ; 不能是 ALTRun.ahk 的子串,否则按键绑定会有问题
, g_WinName := "ALTRun - Ver 08.2023"         ; 主窗口标题
, g_OptionsWinName := "ALTRun Options"        ; 选项窗口标题
, g_CmdMgrWinName := "Command Manager"        ; 选项窗口标题
, g_Commands                                  ; 所有命令
, g_FallbackCommands                          ; 当搜索无结果时使用的命令
, g_CurrentInput                              ; 编辑框当前内容
, g_CurrentCommand                            ; 当前匹配到的第一条命令
, g_CurrentCommandList := Object()            ; 当前匹配到的所有命令
, g_UseDisplay                                ; 命令使用了显示框
, g_HistoryCommands := Object()               ; 历史命令
, g_UseFallback                               ; 使用备用的命令
, g_PipeArg                                   ; 用来调用管道的参数（结果第三列）
, g_InputBox  := "Edit1"
, g_ListView  := "MyListView"

;=============================================================
; 显示各个控件的ToolTip
;=============================================================
g_EnableSendTo_TT := "Whether to create a 'send to' menu"
g_AutoStartup_TT := "Whether to add a shortcut to boot"
g_InStartMenu_TT := "Whether to add a shortcut to the start menu"
g_IndexDir_TT := "Index location, you can use full path or AHK variable starting with A_, must be separated by '|', the path can contain spaces, without quotation marks"
g_IndexFileType_TT := "The index file types must be separated by '|'"
g_IndexExclude_TT := "excluded files, regular expression"
g_SearchFullPath_TT := "Search full path of the file or command, otherwise only search file name"
g_ShowIcon_TT := "Show icon in file ListView"
g_KeepInputText_TT := "Do not clear the content of the edit box when the window is hidden"
g_TCPath_TT := "TotalCommander path with parameters, eg: C:\OneDrive\Apps\TotalCMD64\Totalcmd64.exe /O /T /S, if empty, use explorer to open"
g_SelectTCPath_TT := "Select Total Commander file path"
g_HideOnDeactivate_TT := "The window closes after the window loses focus"
g_AlwaysOnTop_TT := "Window on top most display"
g_SaveHistory_TT := "Save command history"
g_HistorySize_TT := "Number of recorded history"
g_isLogging_TT := "Enable or Disable log record"
g_AutoRank_TT := "Automatically adjust the command rank priority according to the frequency of use."
g_EscClearInput_TT := "When inputting Esc, if there is content in the input box, it will be cleared, and if there is no content, the window will be closed"
g_Editor_TT := "The editor used to open the configuration file, the default is the editor associated with the resource manager, you can right-click->properties->open method to modify"
g_SendToGetLnk_TT := "If the file sent using the Send To menu is a .lnk shortcut, add the target file after reading the path from the file"
g_Everything_TT := "Everything.exe file path"
g_HideTitle_TT := "Hide Title Bar"
g_ShowTrayIcon_TT := "Whether to show the tray icon"
g_DisplayRows_TT := "The number of rows displayed in the list, if more than 9 rows, the shortcut key to locate this row will be invalid."
g_Col3Width_TT := "The width of the third column in the list"
g_Col4Width_TT := "Width of the fourth column in the list"
g_HideCol2_TT := "Hide the second column, that is, display a column of file and function `nIf hidden, the space of the second column will be allocated to the third column"
g_LVGrid_TT := "Show Grid in command ListView"
g_FontName_TT := "Font Name, eg. Default, Segoe UI, Microsoft Yahei"
g_FontSize_TT := "Font Size, Default is 10"
g_FontColor_TT := "Font Color, eg. cRed, cFFFFAA, cDefault"
g_WinWidth_TT := "Width of ALTRun app window"
g_EditHeight_TT := "Height of input box and detail box"
g_ListHeight_TT := "Command List Height"
g_CtrlColor_TT := "Set Color for Controls in Window"
g_WinColor_TT := "Window background color, including border color, current command detail box color, value can be like: White, Default, EBFFEB, 0xEBFFEB"
g_BackgroundPicture_TT := "Background picture, the background picture can only be displayed in the border part.`nIf there is a splash screen after using the picture, first adjust the size of the picture to solve the window size and improve the loading speed.`nIf the splash screen is still obvious, please Hollow and fill the position of the text box on the picture with a color similar to the text background, or modify it to the transparent color of png"
g_Hotkey1_TT := "Shortcut key 1`nThe priority is higher than the default Alt + series keys, do not modify the Alt mapping unless necessary"
g_Trigger1_TT := "Function to be triggered by Hotkey 1"
g_Hotkey2_TT := "Shortcut key 2`nThe priority is higher than the default Alt + series keys, do not modify the Alt mapping unless necessary"
g_Trigger2_TT := "Function to be triggered by Hotkey 2"
g_Hotkey3_TT := "Shortcut key 3`nThe priority is higher than the default Alt + series keys, do not modify the Alt mapping unless necessary"
g_Trigger3_TT := "Function to be triggered by Hotkey 3"
g_RunCmdAlt_TT := "Press Alt + command number to run the command, untick means Press command number to run the command"
g_EnableCapsLockIME_TT := "Use CapsLock to switch input methods (similar to macOS)"
g_GlobalHotkey1_TT := "Global hotkey 1 to activate ALTRun"
g_GlobalHotkey2_TT := "Global hotkey 2 to activate ALTRun"
g_AutoSwitchDir_TT := "Listary - Auto Switch Dir"
g_FileManager_TT := "Win Title or Class name of the File Manager, separated by '|', default is: ahk_class CabinetWClass|ahk_class TTOTAL_CMD (Windows Explorer and Total Commander)"
g_DialogWin_TT := "Win Title or Class name of the Dialog Box which Listary Switch Dir will take effect, separated by '|', default is: ahk_class #32770"
g_ExcludeWin_TT := "Exclude those windows that not want Listary Switch Dir take effect, separated by '|', default is: ahk_class SysListView32|ahk_exe Explorer.exe"
g_EnableScheduler_TT := "Enable shutdown scheduled task"
g_ShutdownTime_TT := "Set timing for PC auto shutdown"
OK_TT := "Save and Apply the changes"
Cancel_TT := "Discard the changes"

;=============================================================
; Load Config and Set Logger
;=============================================================
Global Log := New Logger(g_LogFile)                                     ; Global Log so that can use in other Lib
Log.Msg("●●●●● ALTRun is starting ●●●●●")

LoadConfig("initialize")                                                ; Load ini config, IniWrite will create it if not exist

;=============================================================
; Create ContextMenu and TrayMenu
;=============================================================
Menu, LV_ContextMenu, Add, Run`tEnter, ContextMenu                      ; ListView ContextMenu
Menu, LV_ContextMenu, Add, Open Path`tCtrl+D, OpenCurrentFileDir
Menu, LV_ContextMenu, Add, Copy Command, ContextMenu
Menu, LV_ContextMenu, Add
Menu, LV_ContextMenu, Add, New Command, CmdMgr
Menu, LV_ContextMenu, Add, Edit Command`tF3, EditCurrentCommand
Menu, LV_ContextMenu, Add, User-defined Command`tF4, UserCommandList
Menu, LV_ContextMenu, Add
Menu, LV_ContextMenu, Add, History `tCtrl+H, History
Menu, LV_ContextMenu, Add, Options `tF2, Options
Menu, LV_ContextMenu, Add, Help `tF1, Help

Menu, LV_ContextMenu, Icon, Run`tEnter, Shell32.dll, -25
Menu, LV_ContextMenu, Icon, Open Path`tCtrl+D, Shell32.dll, -4
Menu, LV_ContextMenu, Icon, Copy Command, Shell32.dll, -243
Menu, LV_ContextMenu, Icon, New Command, Shell32.dll, -1
Menu, LV_ContextMenu, Icon, Edit Command`tF3, Shell32.dll, -16775
Menu, LV_ContextMenu, Icon, User-defined Command`tF4, Shell32.dll, -44
Menu, LV_ContextMenu, Icon, History `tCtrl+H, Shell32.dll, -16741
Menu, LV_ContextMenu, Icon, Options `tF2, Shell32.dll, -16826
Menu, LV_ContextMenu, Icon, Help `tF1, Shell32.dll, -24
Menu, LV_ContextMenu, Default, Run`tEnter                               ; 让 "Run" 粗体显示表示双击时会执行相同的操作.

if (g_ShowTrayIcon)
{
    Menu, Tray, Add, Show, ActivateALTRun
    Menu, Tray, Add
    Menu, Tray, Add, Options `tF2, Options
    Menu, Tray, Add, ReIndex `tCtrl+I, ReindexFiles
    Menu, Tray, Add, Help `tF1, Help
    Menu, Tray, Add
    Menu, SubTray, Add, Script Info, TrayMenu                           ; Create one menu destined to become a submenu of the above menu.
    Menu, SubTray, Add, Script Help, TrayMenu
    Menu, SubTray, Add, Window Spy, TrayMenu
    Menu, Tray, Add, AutoHotkey, :SubTray                               ; Create a submenu in the first menu (a right-arrow indicator)
    Menu, Tray, Add,
    Menu, Tray, Add, Reload `tCtrl+Q, ALTRun_Reload                     ; Call ALTRun_Reload function with Arg=Reload `tCtrl+Q
    Menu, Tray, Add, Exit `tAlt+F4, ExitALTRun

    Menu, Tray, NoStandard
    Menu, Tray, Icon
    Menu, Tray, Icon, Shell32.dll, -25                                  ; if the index of an icon changes between Windows versions but the resource ID is consistent, refer to the icon by ID instead of index
    Menu, Tray, Icon, Show, Shell32.dll, -25
    Menu, Tray, Icon, Options `tF2, Shell32.dll, -16826
    Menu, Tray, Icon, ReIndex `tCtrl+I, Shell32.dll, -16776
    Menu, Tray, Icon, Help `tF1, Shell32.dll, -24
    Menu, Tray, Icon, AutoHotkey, Imageres.dll, -160
    Menu, Tray, Icon, Reload `tCtrl+Q, Shell32.dll, -16739
    Menu, Tray, Icon, Exit `tAlt+F4, Imageres.dll, -5102
    Menu, Tray, Tip, %g_WinName%
    Menu, Tray, Default, Show
    Menu, Tray, Click, 1                                                ; Sets the number of clicks to activate the tray menu's default menu item.
}
;=============================================================
; Load commands database and command history
; Update "SendTo", "Startup", "StartMenu" lnk
;=============================================================
LoadCommands()

if (g_SaveHistory)
{
    LoadHistoryCommands()
}

Log.Msg("Updating 'SendTo' setting...Re=" UpdateSendTo(g_EnableSendTo))
Log.Msg("Updating 'Startup' setting...Re=" UpdateStartup(g_AutoStartup))
Log.Msg("Updating 'StartMenu' setting...Re=" UpdateStartMenu(g_InStartMenu))

;=============================================================
; 主窗口配置代码
;=============================================================
HideTitle    := g_HideTitle ? "-Caption" : ""                           ; Store "-Caption" in HideTitle if g_HideTitle is True, otherwise store ""
AlwaysOnTop  := g_AlwaysOnTop ? "+AlwaysOnTop" : ""                     ; Check Win AlwaysOnTop status
Col2Width    := g_HideCol2 ? 0 : 60                                     ; Check ListView column 2 hide status
Col3Width    := g_HideCol2 ? g_Col3Width+60 : g_Col3Width               ; Adjust column 3 width based on column 2 status
LVGrid       := g_LVGrid ? "Grid" : ""                                  ; Check ListView Grid option
WinHeight    := g_EditHeight + g_ListHeight + 30 + 23                   ; Original WinHeight
ListWidth    := g_WinWidth - 20
HideWin      := ""

Gui, Main:Color, %g_WinColor%, %g_CtrlColor%
Gui, Main:Font, c%g_FontColor% s%g_FontSize%, %g_FontName%
Gui, Main:%HideTitle% %AlwaysOnTop%
Gui, Main:Add, Picture, x0 y0 0x4000000, %g_BGPicture%                  ; If the picture cannot be loaded or displayed, the control is left empty and its W&H are set to zero. So FileExist() is not necessary.
Gui, Main:Add, Edit, x10 y10 w%ListWidth% h%g_EditHeight% -WantReturn v%g_InputBox% gSearchCommand, Type anything here to search...
Gui, Main:Add, ListView, Count15 y+10 w%ListWidth% h%g_ListHeight% v%g_ListView% gLVAction +LV0x00010000 %LVGrid% -Multi AltSubmit, No.|Type|Command|Description ; LVS_EX_DOUBLEBUFFER Avoids flickering.
Gui, Main:Add, StatusBar,,
Gui, Main:Add, Button, x0 y0 w0 h0 Hidden Default gRunCurrentCommand
Gui, Main:Default                                                       ; Set default GUI before any ListView / statusbar update

SB_SetParts(g_WinWidth-120)
LV_ModifyCol(1, "40 Integer")                                           ; set ListView column width and format, Integer can use for sort
LV_ModifyCol(2, Col2Width)
LV_ModifyCol(3, Col3Width)
LV_ModifyCol(4, g_Col4Width)
LV_Modify(0, "-Select")                                                 ; De-select all.
LV_Modify(1, "Select Focus Vis")                                        ; select 1st row
ListResult("Function | F1 | ALTRun Help Index`n"                        ; Show initial list (hints, help, statusbar) on firstRun
         . "Function | F2 | ALTRun Options Settings`n"
         . "Function | F3 | ALTRun Edit current command`n"
         . "Function | F4 | ALTRun User-defined command`n"
         . "Function | ALT+SPACE or ALT+R | Activative ALTRun`n"
         . "Function | Lose Focus or Hotkey or ESC | Close ALTRun`n"
         . "Function | Enter or ALT+No. | Run selected command`n"
         . "Function | UP or DOWN | Select previous or next command`n"
         . "Function | CTRL+D | Open cmd dir with TC or File Explorer"
         , False, False)
SetStatusBar("✨ You have run shortcut " g_RunCount " times by now!")
;=============================================================
; Command line args, Args are %1% %2% or A_Args[1] A_Args[2]
;=============================================================
Log.Msg("Resolving command line args=" A_Args[1] " " A_Args[2])

if (A_Args[1] = "-startup")
{
    Log.Msg("Starting from Startup lnk...")
    HideWin := " Hide"
}

if (A_Args[1] = "-SendTo")
{
    Log.Msg("Starting from SendTo Mode...")
    HideWin := " Hide", CmdMgr(A_Args[2])
}

Gui, Main:Show, Center w%g_WinWidth% h%WinHeight% %HideWin%, %g_WinName%

if (g_HideOnDeactivate)
{
    OnMessage(0x06, "WM_ACTIVATE")
}
OnMessage(0x0200, "WM_MOUSEMOVE")
OnExit("ExitFunc")

;=============================================================
; Set Hotkey for %g_WinName% only
;=============================================================
Hotkey, IfWinActive, %g_WinName%                                        ; Hotkey take effect only when ALTRun actived

Hotkey, !F4, ExitALTRun
Hotkey, Tab, TabFunc
Hotkey, F1, Help
Hotkey, F2, Options
Hotkey, F3, EditCurrentCommand
Hotkey, F4, UserCommandList
Hotkey, ^q, ALTRun_Reload
Hotkey, ^d, OpenCurrentFileDir
Hotkey, ^i, ReindexFiles
Hotkey, ^H, History
Hotkey, ^NumpadAdd, IncreaseRank
Hotkey, ^NumpadSub, DecreaseRank
Hotkey, Down, NextCommand
Hotkey, Up, PrevCommand

;=============================================================
; Run or locate command shortcut: Ctrl Alt Shift + No.
;=============================================================
Loop, % Min(g_DisplayRows, 9)                                           ; Not set hotkey for DisplayRows > 9
{
    if (g_RunCmdAlt)
        Hotkey, !%A_Index%, RunSelectedCommand                          ; ALT + No. run command
    else
        Hotkey, %A_Index%, RunSelectedCommand                           ; 数字键直接启动,小键盘不影响数字输入
    Hotkey, ^%A_Index%, GotoCommand                                     ; Ctrl + No. locate command
}

;=============================================================
; Set Trigger <-> Hotkey and Global Hotkey
;=============================================================
Loop, 3
{
    Hotkey  := % g_Hotkey%A_Index%
    Trigger := % g_Trigger%A_Index%

    if (Hotkey != "" and IsFunc(Trigger))
        Hotkey, %Hotkey%, %Trigger%
}

Hotkey, IfWinActive                                                     ; Omit the parameters to turn off context sensitivity, to make subsequently-created hotkeys work in all windows
Loop, 2
{
    Hotkey, % g_GlobalHotkey%A_Index%, ToggleWindow
}

;=============================================================
; 启动Listary快速切换文件夹功能, 启动AppControl功能
; Set TaskScheduler to turn off computer
;=============================================================
Listary(), AppControl(), TaskScheduler(g_EnableScheduler)

ActivateALTRun()
{
    SetStatusBar("Hint")                                                ; Show hint in StatusBar (update SB before GUI show)
    Gui, Main:Show,,%g_WinName%

    WinWaitActive, %g_WinName%,, 3                                      ; Use WinWaitActive 3s instead of previous Loop method
    {
        GuiControl, Main:Focus, %g_InputBox%
        ControlSend, %g_InputBox%, ^a, %g_WinName%                      ; Select all content in Input Box
    }
}

ToggleWindow()
{
    if WinActive(g_WinName)
    {
        MainGuiClose()
    }
    else
    {
        ActivateALTRun()
    }
}

SearchCommand(command := "")
{
    ;Global
    GuiControlGet, g_CurrentInput, Main:,%g_InputBox%                   ; Get input text

    g_UseDisplay    := false
    result          := ""
    order           := 1
    commandPrefix   := SubStr(g_CurrentInput, 1, 1)
    g_CurrentCommandList := Object()

    if (commandPrefix = "+" or commandPrefix = " " or commandPrefix = ">")
    {
        g_PipeArg := ""

        if (commandPrefix = "+")
        {
            g_CurrentCommand := g_FallbackCommands[1]
        }
        else if (commandPrefix = " ")
        {
            g_CurrentCommand := g_FallbackCommands[2]
        }
        else if (commandPrefix = ">")
        {
            g_CurrentCommand := g_FallbackCommands[5]
        }

        g_CurrentCommandList.Push(g_CurrentCommand)
        ListResult(g_CurrentCommand)
        Return
    }

    for index, element in g_Commands
    {
        _Type := StrSplit(element, " | ")[1]
        _Path := StrSplit(element, " | ")[2]
        _Desc := StrSplit(element, " | ")[3]

        if (_Type = "file")                                             ; Equal (=), case-sensitive-equal (==)
        {
            elementToShow := _Type " | " _Path " | " _Desc              ; Use _Path to show file icons
            if (g_SearchFullPath)
            {
                elementToSearch := _Path " " _Desc
            }
            else
            {
                SplitPath, _Path, fileName
                elementToSearch := fileName " " _Desc                   ; search file name include extension & desc
            }
        }
        else if (_Type = "dir" or _Type = "tender" or _Type = "project")
        {
            SplitPath, _Path, fileName                                  ; Extra name from _Path (if _Type is Dir and has "." in path, nameNoExt will not get full folder name) 

            elementToShow   := _Type " | " fileName " | " _Desc         ; Show folder name only
            if (g_SearchFullPath)
            {
                elementToSearch := _Path " " _Desc
            }
            else
            {
                elementToSearch := fileName " " _Desc                   ; Search dir type + folder name + desc
            }
        }
        else
        {
            elementToShow   := _Type " | " _Path " | " _Desc
            elementToSearch := _Path " " _Desc
        }

        if (FuzzyMatch(elementToSearch, g_CurrentInput))
        {
            g_CurrentCommandList.Push(element)

            if (order = 1)
            {
                g_CurrentCommand := element
                result .= elementToShow
                order++
            }
            else
            {
                result .= "`n" elementToShow
                order++
                if (order > g_DisplayRows)
                    break
            }
        }
    }

    if (result = "")
    {
        if (Eval(g_CurrentInput) != 0)
        {
            ListResult("Eval | " Eval(g_CurrentInput), false, true)
            Return
        }

        g_UseFallback        := true
        g_CurrentCommandList := g_FallbackCommands
        g_CurrentCommand     := g_FallbackCommands[1]

        for index, element in g_FallbackCommands
        {
            if (index = 1)
            {
                result .= element
            }
            else
            {
                result .= "`n" element
            }
        }
    }
    else
    {
        g_UseFallback := false
    }

    ListResult(result, false, false)
}

ListResult(text := "", ActWin := false, UseDisplay := false)            ; 用来显示控制界面 & 用来显示命令结果
{
    if (ActWin)
    {
        ActivateALTRun()                                                ; 会导致快捷计算器失效
    }
    g_UseDisplay := UseDisplay
    
    Gui, Main:Default                                                   ; Set default GUI before update any listview or statusbar
    GuiControl, Main:-Redraw, %g_ListView%                              ; 在加载时禁用重绘来提升性能.
    LV_Delete()

    if (g_ShowIcon)
    {
        ImageListID1 := IL_Create(10, 5)                                ; Create an ImageList so that the ListView can display some icons
        IL_Add(ImageListID1, "shell32.dll", -4)                         ; Add folder icon for dir type (IconNo=1)
        IL_Add(ImageListID1, "shell32.dll", -25)                        ; Add app default icon for function type (IconNo=2)
        IL_Add(ImageListID1, "shell32.dll", -512)                       ; Add Browser icon for url type (IconNo=3)
        IL_Add(ImageListID1, "shell32.dll", -22)                        ; Add control panel icon for control type (IconNo=4)
        IL_Add(ImageListID1, "Calc.exe", -1)                             ; Add calculator icon for Eval type (IconNo=5)
        LV_SetImageList(ImageListID1)                                   ; Attach the ImageLists to the ListView so that it can later display the icons
        IconNo  := ""
        VarSetCapacity(sfi, sfi_size := 698)                            ; 计算 SHFILEINFO 结构需要的缓存大小
    }
    
    Loop Parse, text, `n, `r
    {
        if (!InStr(A_LoopField, " | "))                                 ; If do not have " | " then Return result and next line
        {
            _Type    := "Display"
            _Path    := A_LoopField
            _Desc    := ""
        }        
        else
        {
            _Type    := Trim(StrSplit(A_LoopField, " | ")[1])
            _Path    := Trim(StrSplit(A_LoopField, " | ")[2])           ; Must store in var for future use, trim space
            _Desc    := Trim(StrSplit(A_LoopField, " | ")[3])
        }
        _AbsPath := AbsPath(_Path)

        ; 建立唯一的扩展 ID 以避免变量名中的非法字符, 例如破折号. 这种使用唯一 ID 的方法也会执行地更好, 因为在数组中查找项目不需要进行搜索循环.
        SplitPath, _AbsPath,,, FileExt                                  ; 获取文件扩展名.

        if (g_ShowIcon)
        {
            if _Type contains Dir,Tender,Project
            {
                ExtID := "dir", IconNo := 1
            }
            else if _Type contains Function,CMD
            {
                ExtID := "cmd", IconNo := 2
            }
            else if _Type contains URL
            {
                ExtID := "url", IconNo := 3
            }
            else if _Type contains Control
            {
                ExtID := "cpl", IconNo := 4
            }
            else if _Type contains Eval
            {
                ExtID := "eval", IconNo := 5
            }
            else if FileExt in EXE,ICO,ANI,CUR,LNK
            {
                ExtID := FileExt, IconNo := 0                           ; ExtID 特殊 ID 作为占位符, IconNo 进行标记这样每种类型就含有唯一的图标.
            }
            else                                                        ; 其他的扩展名/文件类型, 计算它们的唯一 ID.
            {
                ExtID := 0                                              ; 进行初始化来处理比其他更短的扩展名.
                Loop 4                                                  ; 限制扩展名为 4 个字符, 这样之后计算的结果才能存放到 64 位值 (use 4 due to some short folder name has dot)
                {
                    ExtChar := SubStr(FileExt, A_Index, 1)
                    if not ExtChar                                      ; 没有更多字符了.
                        break
                    ExtID := ExtID | (Ord(ExtChar) << (8 * (A_Index - 1))) ; 把每个字符与不同的位位置进行运算来得到唯一 ID
                }
                IconNo := IconList%ExtID%                               ; 检查此文件扩展名的图标是否已经在图像列表中. 如果是, 可以避免多次调用并极大提高性能, 尤其对于包含数以百计文件的文件夹而言
            }

            if (!IconNo)                                                ; 此扩展名还没有相应的图标, 所以进行加载.
            {
                ; 获取与此文件扩展名关联的高质量小图标:
                if (!DllCall("Shell32\SHGetFileInfoW", "Str", _AbsPath, "UInt", 0, "Ptr", &sfi, "UInt", sfi_size, "UInt", 0x101))  ; 0x101 为 SHGFI_ICON+SHGFI_SMALLICON
                    IconNo = 9999999                                    ; 如果未成功加载到图标, 把它设置到范围外来显示空图标.
                else                                                    ; 成功加载图标.
                {
                    hIcon := NumGet(sfi, 0)                             ; 从结构中提取 hIcon 成员
                    IconNo := DllCall("ImageList_ReplaceIcon", "ptr", ImageListID1, "int", -1, "ptr", hIcon) + 1 ; 直接添加 HICON 到图标列表, 下面加上 1 来把返回的索引从基于零转换到基于1
                    DllCall("DestroyIcon", "ptr", hIcon)                ; 现在已经把它复制到图像列表, 所以应销毁原来的
                    IconList%ExtID% := IconNo                           ; 缓存图标来节省内存并提升加载性能:
                }
            }
            LV_Add("Icon"IconNo, A_Index, _Type, _Path, _Desc)
        }
        else
            LV_Add(, A_Index, _Type, _Path, _Desc)
    }

    LV_Modify(0, "-Select")                                             ; De-select all.
    LV_Modify(1, "Select Focus Vis")                                    ; select 1st row
    GuiControl, Main:+Redraw, %g_ListView%                              ; 重新启用重绘 (上面把它禁用了)
    SetStatusBar()
}

AbsPath(Path, KeepRunAs := 0)                                           ; Convert path to absolute path
{
    if (!KeepRunAs)
    {
        Path := StrReplace(Path,  "*RunAs ", "")                        ; Remove *RunAs (Admin Run) to get absolute path
    }

    if (InStr(Path, "A_"))                                              ; Resolve path like A_ScriptDir
    {
        Path := %Path%
    }

    EnvGet, Temp, Temp
    Path := StrReplace(Path, "%Temp%", Temp)

    Path := StrReplace(Path, "%OneDrive%", OneDrive)                    ; Convert OneDrive to absolute path due to #NoEnv
    Path := StrReplace(Path, "%OneDriveConsumer%", OneDriveConsumer)    ; Convert OneDrive to absolute path due to #NoEnv
    Path := StrReplace(Path, "%OneDriveCommercial%", OneDriveCommercial) ; Convert OneDrive to absolute path due to #NoEnv
    Return Path
}

RelativePath(Path)                                                      ; Convert path to relative path
{
    Path := StrReplace(Path, OneDriveConsumer, "%OneDriveConsumer%")
    Path := StrReplace(Path, OneDriveCommercial, "%OneDriveCommercial%")
    Return Path
}

RunCommand(originCmd)
{
    MainGuiClose()                                                      ; 先隐藏或者关闭窗口,防止出现延迟的感觉
    ParseArg()
    g_UseDisplay := false
    Log.Msg("Execute(" g_RunCount ")=" originCmd)

    _Type := StrSplit(originCmd, " | ")[1]
    _Path := StrSplit(originCmd, " | ")[2]
    _Path := AbsPath(_Path, 1)

    if (_Type = "file")
    {
        SplitPath, _Path, , WorkingDir, ,
        if (Arg = "")
        {
            Run, %_Path%, %WorkingDir%, UseErrorLevel
        }
        else
        {
            Run, %_Path% "%Arg%", %WorkingDir%, UseErrorLevel
        }
        if ErrorLevel
            MsgBox Could not open "%_Path%"
    }
    else if _Type in dir,tender,project
    {
        OpenDir(_Path)
    }
    else if (_Type = "function" and IsFunc(_Path))
    {
        %_Path%()
    }
    else if (_Type = "cmd")
    {
        RunWithCmd(_Path)
    }
    else                                                                ; for type: url, control & all other un-defined type
    {
        Run, %_Path%
    }

    if (g_SaveHistory && _Path != "History")                            ; Save command history
    {
        g_HistoryCommands.InsertAt(1, originCmd " /arg=" Arg)

        if (g_HistoryCommands.Length() > g_HistorySize)
        {
            g_HistoryCommands.Pop()
        }
    }

    if (g_AutoRank)
    {
        ChangeRank(originCmd)
    }

    g_PipeArg := ""
    FullPipeArg := ""
}

TabFunc()
{
    GuiControlGet, CurrCtrl, Main:FocusV                                ; Limit tab to switch between g_InputBox & ListView only
    if (CurrCtrl = g_InputBox)
    {
        GuiControl, Main:Focus, %g_ListView%
    }
    else
    {
        GuiControl, Main:Focus, %g_InputBox%
    }
}

PrevCommand()
{
    ChangeCommand(-1, False)
}

NextCommand()
{
    ChangeCommand(1, False)
}

GotoCommand()
{
    index := SubStr(A_ThisHotkey, 0, 1)                                 ; Get index from hotkey (select specific command = Shift + index)
    g_CurrentCommand := g_CurrentCommandList[index]

    if (g_CurrentCommand != "")
    {
        ChangeCommand(index, True)
    }
}

ChangeCommand(Step = 1, ResetSelRow = False)
{
    Gui, Main:Default                                                   ; Use it before any LV update

    SelRow := ResetSelRow ? Step : LV_GetNext() + Step                  ; Get target row no. to be selected
    SelRow := SelRow > LV_GetCount() ? 1 : SelRow                       ; Listview cycle selection (Mod not suitable)
    SelRow := SelRow < 1 ? LV_GetCount() : SelRow
    g_CurrentCommand := g_CurrentCommandList[SelRow]                    ; Get current command from selected row

    LV_Modify(0, "-Select")
    LV_Modify(SelRow, "Select Focus Vis")                               ; make new index row selected, Focused, and Visible
    SetStatusBar()
}

;=============================================================
; GuiContextMenu right click on GUI Control
;=============================================================
MainGuiContextMenu()                                                    ; 运行此标签来响应右键点击或按下 Appskey, 指定响应窗口为Main
{
    if (A_GuiControl = g_ListView)                                      ; 仅在 ListView 中点击时才显示菜单
        Menu, LV_ContextMenu, Show, %A_GuiX%, %A_GuiY%                  ; 在提供的坐标处显示菜单, 应该使用 A_GuiX & A_GuiY,因为即使用户按下 Appskey 它们也会提供正确的坐标
}

ContextMenu()                                                           ; ListView ContextMenu actions
{
    Gui, Main:Default                                                   ; Use it before any LV update
    focusedRow := LV_GetNext(0, "Focused")                              ; Check focused row, only operate focusd row instead of all selected rows
    if (!focusedRow)                                                    ; if not found
        return

    g_CurrentCommand := g_CurrentCommandList[focusedRow]                ; Get current command from focused row
    If (A_ThisMenuItem = "Run`tEnter")                                  ; 用户在上下文菜单中选择了 "Run`tEnter"
    {
        RunCommand(g_CurrentCommand)
    }
    else if (A_ThisMenuItem = "Copy Command")
    {
        A_Clipboard := StrSplit(g_CurrentCommand, " | ")[2]
    }
}

LVAction()                                                              ; Double click and normal left click on ListView behavior
{
    focusedRow := LV_GetNext(0, "Focused")                              ; 查找焦点行, 仅对焦点行进行操作而不是所有选择的行:
    if (!focusedRow)                                                    ; 没有焦点行
        return

    g_CurrentCommand := g_CurrentCommandList[focusedRow]                ; Get current command from focused row
    
    if (A_GuiEvent = "DoubleClick" and g_CurrentCommand)                ; Double click behavior, if g_CurrentCommand = "" eg. first tip page, run it will clear SEC_USERCMD, SEC_INDEX, SEC_DFTCMD
    {
        RunCommand(g_CurrentCommand)
    }
    else if (A_GuiEvent = "Normal")                                     ; left click behavior
    {
        SetStatusBar()
    }
}

TrayMenu()                                                              ;AutoHotkey标准托盘菜单
{
    If ( A_ThisMenuItem = "Script Info" )
        ListVars
    If ( A_ThisMenuItem = "Script Help" )
        Run % A_AhkPath
    If ( A_ThisMenuItem = "Window Spy" )
        Run, % StrReplace(A_AhkPath, "\AutoHotkey.exe", "\WindowSpy.ahk")
}

MainGuiEscape()
{
    if (g_EscClearInput and g_CurrentInput)
    {
        ClearInput()
    }
    else
    {
        MainGuiClose()
    }
}

MainGuiClose()                                                          ; If GuiClose is a function, the GUI is hidden by default
{
    if (!g_KeepInputText)
    {
        ClearInput()
    }
    Gui, Main:Hide
}

ExitALTRun()
{
    ExitApp
}

ALTRun_Reload()
{
    Reload
}

ExitFunc(exitReason, exitCode)
{
    SaveConfig("History")                                               ; Save ini in OnExit function, ExitApp/Reload will auto call OnExit.
    Log.Msg("Exiting ALTRun...Reason=" exitReason)
}

UserCommandList()
{
    if (g_Editor != "")
    {
        Run, % g_Editor " /m " SEC_USERCMD " """ g_IniFile """"         ; /m Match text
    }
    else
    {
        Run, % g_IniFile
    }
}

ClearInput()
{
    GuiControl, Main:Text, %g_InputBox%,
    GuiControl, Main:Focus, %g_InputBox%
}

SetStatusBar(Mode := "Command")                                         ; Set StatusBar text, Mode 1: Current command (default), 2: Hint, 3: Any text
{
    Gui, Main:Default                                                   ; Set default GUI window before any ListView / StatusBar operate
    if (Mode = "Command")
    {
        SBText := "🎯 " StrSplit(g_CurrentCommand, " | ")[2]
    }
    else if (Mode = "Hint")
    {
        g_RunCount ++
        Random, HintIndex, 1, g_Hints.Length()                          ; 随机抽出一条提示信息
        SBText := "✨ " g_Hints[HintIndex]                               ; 每次有效激活窗口之后StatusBar展示提示信息
    }
    else
    {
        SBText := Mode
    }
    SB_SetText(SBText, 1), SB_SetText("RunCount: "g_RunCount, 2)        ; Omite SB_SetIcon for better performance
}

RunCurrentCommand()
{
    RunCommand(g_CurrentCommand)
}

ParseArg()
{
    global
    if (g_PipeArg != "")
    {
        Arg := g_PipeArg
        Return
    }

    commandPrefix := SubStr(g_CurrentInput, 1, 1)

    if (commandPrefix = "+" || commandPrefix = " " || commandPrefix = ">") ; 分号或者冒号的情况,直接取命令为参数
    {
        Arg := SubStr(g_CurrentInput, 2)
        Return
    }

    if (InStr(g_CurrentInput, " ") && !g_UseFallback)                   ; 用空格来判断参数
    {
        Arg := SubStr(g_CurrentInput, InStr(g_CurrentInput, " ") + 1)
    }
    else if (g_UseFallback)
    {
        Arg := g_CurrentInput
    }
    else
    {
        Arg := ""
    }
}

FuzzyMatch(Haystack, Needle)
{
    Needle := StrReplace(Needle, "+", "\+")                             ; for Eval (preceded by a backslash to be seen as literal)
    Needle := StrReplace(Needle, "*", "\*")                             ; for Eval (preceded by a backslash to be seen as literal)
    
    Needle := StrReplace(Needle, " ", ".*")                             ; RegExMatch should able to search with space as & separater, but do not know now, use this way first.
    Return RegExMatch(Haystack, "imS)" Needle)
}

ChangeRank(originCmd, showRank := false, inc := 1)
{
    RANKSEC := SEC_DFTCMD "|" SEC_USERCMD "|" SEC_INDEX
    Loop Parse, RANKSEC, |                                              ; Update Rank for related sections
    {
        IniRead, Rank, %g_IniFile%, %A_LoopField%, %originCmd%, KeyNotFound

        if (Rank = "KeyNotFound" or Rank = "ERROR" or originCmd = "")   ; If originCmd not exist in this section, then check next section
        {
            continue                                                    ; Skips the rest of a loop and begins a new one.
        }
        else if Rank is integer                                         ; If originCmd exist in this section, then update it's rank.
        {
            Rank += inc
        }
        else
        {
            Rank := inc
        }

        if (Rank < 0)                                                   ; 如果降到负数,都设置成 -1,然后屏蔽/排除
        {
            Rank := -1
        }
        IniWrite, %Rank%, %g_IniFile%, %A_LoopField%, %originCmd%       ; Update new Rank for originCmd

        if (showRank)
        {
            SetStatusBar("✨ Rank for current command adjusted to : " Rank)
        }
    }
    LoadCommands()                                                      ; New rank will take effect in real-time by LoadCommands again
}

RunSelectedCommand()
{
    index := SubStr(A_ThisHotkey, 0, 1)
    RunCommand(g_CurrentCommandList[index])
}

IncreaseRank()
{
    ChangeRank(g_CurrentCommand, true)
}

DecreaseRank()
{
    ChangeRank(g_CurrentCommand, true, -1)
}

LoadCommands(LoadRank := True)
{
    g_Commands          := Object()                                     ; Clear g_Commands list
    g_FallbackCommands  := Object()                                     ; Clear g_FallbackCommands list
    RankString          := ""

    RANKSEC := LoadConfig("commands")                                   ; Read built-in command & user commands and index commands whole sections
    Loop Parse, RANKSEC, `n                                             ; read each line, separate key and value
    {
        command := StrSplit(A_LoopField, "=")[1]                        ; pass first string (key) to command
        rank    := StrSplit(A_LoopField, "=")[2]                        ; pass second string (value) to rank

        if (command != "" && rank > 0)
        {
            RankString .= rank "`t" command "`n"
        }
    }
    Sort, RankString, R N
    Loop Parse, RankString, `n
    {
        command := StrSplit(A_LoopField, "`t")[2]
        g_Commands.Push(command)
    }
    
    FALLBACKCMDSEC := LoadConfig("fallbackcmd")                         ;read whole section, initialize it if section not exist
    Loop Parse, FALLBACKCMDSEC, `n                                      ;read each line, get each FBCommand (Rank not necessary)
    {
        FBCommand  := StrSplit(A_LoopField, " | ")[2]
        if (IsFunc(FBCommand))
        {
            g_FallbackCommands.Push(A_LoopField)
        }
    }
    Log.Msg("Commands list loaded...")
    Return
}

LoadHistoryCommands()
{
    Loop %g_HistorySize%
    {
        IniRead, History, %g_IniFile%, %SEC_HISTORY%, %A_Index%
        g_HistoryCommands.Push(History)
    }
}

History()
{
    result := ""
    Loop %g_HistorySize%
    {
        result .= g_HistoryCommands[A_Index] "`n"
    }
    
    ListResult(result, true, false)
}

GetCmdOutput(command)
{
    TempFileName := "ALTRun.stdout.log"
    FullCommand = %ComSpec% /C "%command% > %TempFileName%"

    RunWait, %FullCommand%, %A_Temp%, Hide
    FileRead, result, %A_Temp%\%TempFileName%
    FileDelete, %A_Temp%\%TempFileName%
    result := RTrim(result, "`r`n")                                     ; Remove result rightmost/last "`r`n"
    Return result
}

GetRunResult(command)                                                   ;运行CMD并取返回结果方式2
{
    shell := ComObjCreate("WScript.Shell")                              ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
    exec := shell.Exec(ComSpec " /C " command)                          ; Execute a single command via cmd.exe
    Return exec.StdOut.ReadAll()                                        ; Read and Return the command's output
}

RunWithCmd(command)
{
    Run, % ComSpec " /C " command " & pause"
}

OpenDir(Path, isOpenContainer := False)
{
    Path := AbsPath(Path)

    if (isOpenContainer)
    {
        if (g_TCPath)
        {
            Run, %g_TCPath% " /P " "%Path%",, UseErrorLevel             ; /P Parent folder
        }
        else
        {
            Run, Explorer.exe /select`, "%Path%",, UseErrorLevel
        }
    }
    else
    {
        if (g_TCPath)
        {
            Run, %g_TCPath% "%Path%",, UseErrorLevel                    ; /S switch TC /L as Source, /R as Target. /O: If TC is running, active it. /T: open in new tab
        }
        else
        {
            Run, Explorer.exe "%Path%",, UseErrorLevel
        }
    }

    if ErrorLevel
    {
        MsgBox, 4096, %g_WinName%, Error found, error code : %A_LastError%
    }
    Log.Msg("Opening Dir="Path)
}

OpenCurrentFileDir()
{
    OpenDir(StrSplit(g_CurrentCommand, " | ")[2], True)
}

EditCurrentCommand()
{
    if (g_Editor != "")
    {
        Run, % g_Editor " /m " """" g_CurrentCommand """" " """ g_IniFile """" ; /m Match text, locate to current command
    }
    else
    {
        Run, % g_IniFile
    }

    ;CmdMgr(g_CurrentCommand, "EditCommand")
}

;=============================================================
; MouseMove Behavior
;=============================================================
WM_MOUSEMOVE(wParam, lParam)
{
    if (wParam = 1)                                                     ; LButton
    {
        PostMessage, 0xA1, 2, , , A                                     ; WM_NCLBUTTONDOWN
    }

    if WinActive(g_OptionsWinName)                                      ; to show tooltip for controls, limit to Options Win
    {
        static CurrControl := "", PrevControl := "", _TT := ""          ; _TT is kept blank for use by the ToolTip command below.
        CurrControl := A_GuiControl
        if (CurrControl != PrevControl)                                 ; ToolTip for each control
        {
            ToolTip                                                     ; Turn off any previous tooltip.
            Try                                                         ; Using try will guard "CurrControl" against all possible errors
                ToolTip, % %CurrControl%_TT                             ; The leading percent sign tell it to use an expression.
            Catch
                ToolTip
            SetTimer, RemoveToolTip, -10000
            PrevControl := CurrControl
        }
    }
}

RemoveToolTip()
{
    ToolTip
    SetTimer, RemoveToolTip, Off
}

;=============================================================
; 窗口失去焦点后隐藏
;=============================================================
WM_ACTIVATE(wParam, lParam)
{
    if (wParam > 0)                                                     ; wParam > 0: window being activated
    {
        Return
    }
    else if (wParam <= 0 && WinExist(g_WinName) && !g_UseDisplay)       ; wParam <= 0: window being deactivated (lost focus)
    {
        MainGuiClose()
    }
}

UpdateSendTo(create := true)                                            ; the lnk in SendTo must point to a exe
{
    lnkPath := StrReplace(A_StartMenu, "\Start Menu", "\SendTo\") "ALTRun.lnk"

    if (!create)
    {
        FileDelete, %lnkPath%
        Return "SendTo lnk cleaned up"
    }

    if (A_IsCompiled)
        FileCreateShortcut, "%A_ScriptFullPath%", %lnkPath%, ,-SendTo
        , Send command to ALTRun User Command list, Shell32.dll, , -25
    else
        FileCreateShortcut, "%A_AhkPath%", %lnkPath%, , "%A_ScriptFullPath%" -SendTo
        , Send command to ALTRun User Command list, Shell32.dll, , -25
    Return "updated"
}

UpdateStartup(create := true)
{
    lnkPath := A_Startup "\ALTRun.lnk"

    if (!create)
    {
        FileDelete, %lnkPath%
        Return "Startup lnk cleaned up"
    }

    FileCreateShortcut, %A_ScriptFullPath%, %lnkPath%, %A_ScriptDir%
        , -startup, ALTRun - An effective launcher, Shell32.dll, , -25
    Return "updated"
}

UpdateStartMenu(create := true)
{
    lnkPath := A_Programs "\ALTRun.lnk"

    if (!create)
    {
        FileDelete, %lnkPath%
        Return "Start Menu lnk cleaned up"
    }

    FileCreateShortcut, %A_ScriptFullPath%, %lnkPath%, %A_ScriptDir%
        , -StartMenu, ALTRun, Shell32.dll, , -25
    Return "updated"
}

TaskScheduler(SchEnable = False)
{

    TaskSch_Clean = SchTasks /delete /TN AHK_Shutdown /F                ; Delete old scheduler, /TN: TaskName
    Log.Msg("Cleaning task scheduler...Re=" GetCmdOutput(TaskSch_Clean)) ; Run and get output, record into log
    
    if (SchEnable)                                                      ; If enable task scheduler
    {
        TaskSch_Add = SchTasks /create /TN AHK_Shutdown /ST %g_ShutdownTime% /SC once /TR "shutdown /s /t 60" /F
        Log.Msg("Adding task scheduler(" g_ShutdownTime " shutdown)...Re=" GetCmdOutput(TaskSch_Add))
    }
}

ReindexFiles()                                                          ; Re-create Index section
{
    IniDelete, %g_IniFile%, %SEC_INDEX%
    for dirIndex, dir in StrSplit(g_IndexDir, "|")
    {
        searchPath := AbsPath(dir)

        for extIndex, ext in StrSplit(g_IndexFileType, "|")
        {
            Loop Files, %searchPath%\%ext%, R
            {
                if (g_IndexExclude != "" && RegExMatch(A_LoopFileLongPath, g_IndexExclude))
                {
                    continue                                            ; Skip this file and move on to the next loop.
                }
                IniWrite, 1, %g_IniFile%, %SEC_INDEX%, File | %A_LoopFileLongPath% ; Assign initial rank to 1
                Progress, %A_Index%, %A_LoopFileName%, ReIndexing..., ReindexFiles
            }
        }
        Progress, Off
    }

    Log.Msg("Indexing search database...")
    TrayTip, %g_WinName%, ReIndex database finish successfully. , 8
    LoadCommands()
}

Help()
{
    Options(Arg, 7)                                                     ; Open Options window 7th tab (help tab)
}

;===========================================================================================
; Library - Listary ( QuickSwitch Function )
; 仿照 Listary 快速切换文件夹功能
; 在保存/打开对话框中点击菜单项,可以更换对话框到相应路径, 增加自动切换路径功能
; Ctrl+G 将对话框路径切换到TC的路径, Ctrl+E 将对话框路径切换到资源管理器的路径
;===========================================================================================
Listary()
{
    Log.Msg("Starting Listary Function...")

    Loop Parse, g_FileManager, |                                        ; QuickSwitch File Manager Class, default is Windows Explorer & Total Commander
    {
        GroupAdd, FileManager, %A_LoopField%
    }

    Loop Parse, g_DialogWin, |                                          ; 需要QuickSwith的窗口, 包括打开/保存对话框等
    {
        GroupAdd, DialogBox, %A_LoopField%
    }

    Loop Parse, g_ExcludeWin, |                                         ; 排除特定窗口,避免被 Auto-QuickSwitch 影响
    {
        GroupAdd, ExcludeWin, %A_LoopField%
    }

    if(g_AutoSwitchDir)
    {
        Log.Msg("Listary Auto-QuickSwitch Enabled.")
        Loop
        {
            WinWaitActive ahk_class TTOTAL_CMD
                WinGet, ThisHWND, ID, A
            WinWaitNotActive

            If(WinActive("ahk_group DialogBox") && !WinActive("ahk_group ExcludeWin")) ; 检测当前窗口是否符合打开保存对话框条件
            {
                WinGetActiveTitle, Title
                WinGet, ActiveProcess, ProcessName, A

                TrayTip, Listary Function,  Dialog detected`, Active window info `nahk_title = %Title% `nahk_exe = %ActiveProcess%
                Log.Msg("Listary dialog detected, active window ahk_title=" Title ", ahk_exe=" ActiveProcess)
                ChangePath(GetTC())                                     ; NO Return, as will terimate loop (AutoSwitchDir)
            }
        }
    }
    Hotkey, IfWinActive, ahk_group DialogBox                            ; 设置对话框路径定位热键,为了不影响其他程序热键,设置只对打开/保存对话框生效
    Hotkey, %g_TotalCMDDir%, LocateExplorer                                          ; Ctrl+E 把打开/保存对话框的路径定位到资源管理器当前浏览的目录
    Hotkey, %g_TotalCMDDir%, LocateTC                                                ; Ctrl+G 把打开/保存对话框的路径定位到TC当前浏览的目录
    Hotkey, IfWinActive
}

LocateExplorer()
{
    ChangePath(GetExplorer())
}
LocateTC()
{
    ChangePath(GetTC())
}

GetTC()                                                                 ; 获取TC 当前文件夹路径
{
    ClipSaved := ClipboardAll 
    Clipboard :=
    SendMessage 1075, 2029, 0, , ahk_class TTOTAL_CMD
    ClipWait, 200
    OutDir=%Clipboard%\                                                 ; 结尾添加\ 符号,变为路径,试图解决AutoCAD不识别路径问题
    Clipboard := ClipSaved 
    ClipSaved := 
    Return OutDir
}

GetExplorer()                                                           ; 获取Explorer路径
{
    Loop,9
    {
        ControlGetText, Dir, ToolbarWindow32%A_Index%, ahk_class CabinetWClass
    } until (InStr(Dir,"Address"))
 
    Dir:=StrReplace(Dir,"Address: ","")
    if (Dir="Computer")
        Dir:="C:\"

    If (SubStr(Dir,2,2) != ":\")                                             ; then Explorer lists it as one of the library directories such as Music or Pictures
        Dir:=% "C:\Users\" A_UserName "\" Dir

    Return Dir
}

ChangePath(Dir)
{
    ControlGetText, w_Edit1Text, Edit1, A
    ControlClick, Edit1, A
    ControlSetText, Edit1, %Dir%, A
    ControlSend, Edit1, {Enter}, A
    ;Sleep,100
    ;ControlSetText, Edit1, %w_Edit1Text%, A                            ;还原之前的窗口 File Name 内容, 在选择文件的对话框时没有问题, 但是在选择文件夹的对话框有Bug,所以暂时注释掉
    Log.Msg("Listary Change Path=" Dir)
}

;============================= 命令管理窗口 =============================
CmdMgr(Path := "", Mode := "AddCommand")
{
    Global
    Log.Msg("Starting Command Manager... Args=" Path)

    if (Mode = "EditCommand")
    {
        _Type := StrSplit(Path, " | ")[1]
        _Path := StrSplit(Path, " | ")[2]
        _Desc := StrSplit(Path, " | ")[3]
        IniRead, _Rank, %g_IniFile%, %SEC_USERCMD%, %Path%, 1

        Tabs := "Function|URL|Command|File|Dir|Tender|Project"

        Loop, Parse, Tabs, |
        {
            if (A_LoopField = _Type)
            {
                _Type := A_Index
                Break
            }
        }
    }
    else
    {
        SplitPath Path, _Desc, fileDir, fileExt, nameNoExt, fileDrive   ; Extra name from _Path (if _Type is dir and has "." in path, nameNoExt will not get full folder name) 
        
        if InStr(FileExist(Path), "D")                                  ; True only if the file exists and is a directory.
        {
            _Type := 5                                                  ; It is a normal folder

            if InStr(Path, "PROPOSALS & TENDERS")                       ; Check if the path contain "PROPOSALS & TENDERS"
            {
                _Type := 6, _Desc := ""
            }
            else if InStr(Path, "DESIGN PROJECTS")                      ; Check if the path contain "DESIGN PROJECTS"
            {
                _Type := 7, _Desc := ""
            }
        }
        else                                                            ; From command "New Command" or GUI context menu "New Command"
        {
        _Desc := Arg
        }
        
        if (fileExt = "lnk" && g_SendToGetLnk)
        {
            FileGetShortcut, %Path%, Path, fileDir, fileArg, _Desc
            Path .= " " fileArg
        }

        _Path := RelativePath(Path)
        _Rank := 1                                                      ; Assign initial Rank=1
    }

    Gui, CmdMgr:New
    Gui, CmdMgr:Font, s8, Century Gothic, wRegular
    Gui, CmdMgr:Margin, 5, 5
    Gui, CmdMgr:Add, GroupBox, w550 h260, Add / Edit Command
    Gui, CmdMgr:Add, Text, xp+20 yp+35, Command Type: 
    Gui, CmdMgr:Add, DropDownList, xp+120 yp-5 w150 v_Type Choose%_Type%, Function|URL|Command|File||Dir|Tender|Project|
    Gui, CmdMgr:Add, Text, xp-120 yp+50, Command Path: 
    Gui, CmdMgr:Add, Edit, xp+120 yp-5 w350 v_Path, %_Path%
    Gui, CmdMgr:Add, Button, xp+355 yp w30 hp gSelectCmdPath, ...
    Gui, CmdMgr:Add, Text, xp-475 yp+100, Description: 
    Gui, CmdMgr:Add, Edit, xp+120 yp-5 w350 v_Desc, %_Desc%
    Gui, CmdMgr:Add, Text, xp-120 yp+50, Rank (default is 1): 
    Gui, CmdMgr:Add, Edit, xp+120 yp-5 w350 v_Rank, %_Rank%
    Gui, CmdMgr:Add, Button, Default x415 w65, OK
    Gui, CmdMgr:Add, Button, xp+75 yp w65, Cancel

    Gui, CmdMgr:Show, AutoSize, %g_CmdMgrWinName%
    Return
}

SelectCmdPath()
{
    Global
    Gui +OwnDialogs                                                     ; Make open dialog Modal
    Gui, CmdMgr:Submit, Nohide                                          ; 保存每个控件的内容到其关联变量中.
    if(_Type = "Dir" )
    {
        FileSelectFolder, _Path, , 3
        if ( _Path != "")
        {
            GuiControl,, _Path, %_Path%
        }
    }
    else
    {
        FileSelectFile, _Path, 3, , Select Path, All File (*.*)
        if (_Path != "")
        {
            GuiControl,, _Path, %_Path%
        }
    }
    SplitPath _Path, fileName, fileDir, fileExt, nameNoExt, drive       ; Extra name from _Path (if _Type is dir and has "." in path, nameNoExt will not get full folder name) 
    GuiControl,, _Desc, %fileName%
}

CmdMgrButtonOK()
{
    Global
    Gui, CmdMgr:Submit                                                  ; 保存每个控件的内容到其关联变量中
    _Desc := _Desc ? "| " _Desc : _Desc

    if (_Path = "")
    {
        MsgBox, Please input correct command path!
        Return
    }
    else
    {
        IniWrite, %_Rank%, %g_IniFile%, %SEC_USERCMD%, %_Type% | %_Path% %_Desc%
    }

    MsgBox,, %g_CmdMgrWinName%, Command added successfully!
    LoadCommands()
}

CmdMgrGuiEscape()
{
    Gui, CmdMgr:Destroy
}

CmdMgrButtonCancel()
{
    Gui, CmdMgr:Destroy
}

CmdMgrGuiClose()
{
    Gui, CmdMgr:Destroy
}

;=========================================================
; AppControl (Ctrl+D 自动添加日期, 鼠标中间激活PT Tools)
AppConTrol()
{
    GroupAdd, FileListMangr, ahk_class TTOTAL_CMD                       ; 针对TC文件列表重命名
    GroupAdd, FileListMangr, ahk_class CabinetWClass                    ; 针对Windows 资源管理器文件列表重命名
    GroupAdd, FileListMangr, ahk_class Progman                          ; 针对Windows 桌面文件重命名
    ;GroupAdd, FileListMangr, ahk_class TCOMBOINPUT                     ; 针对TC F7创建新文件夹对话框（可单独出来用isFile:= True来控制不考虑后缀的影响）
    GroupAdd, FileListMangr, ahk_class TSTDTREEDLG                      ; 针对TC 新建其他格式文件如txt, rtf, docx...
    GroupAdd, FileListMangr, ahk_class #32770                           ; 针对资源管理器文件保存对话框
    
    Hotkey, IfWinActive, ahk_group FileListMangr                        ; 针对所有设定好的程序 按Ctrl+D自动在文件(夹)名之后添加日期
    Hotkey, ^D, RenameWithDate
    Hotkey, IfWinActive, ahk_class TCmtEditForm                         ; 针对TC File Comment对话框 按Ctrl+D自动在备注文字之后添加日期
    Hotkey, ^D, LineEndAddDate
    Hotkey, IfWinActive, ahk_class Notepad2                             ; 针对Notepad2 (原Ctrl+D 为重复当前行)
    Hotkey, ^D, LineEndAddDate
    Hotkey, IfWinActive, ahk_class TCOMBOINPUT                          ; 针对TC F7创建新文件夹对话框（可单独出来用isFile:= True来控制不考虑后缀的影响）
    Hotkey, ^D, LineEndAddDate
    Hotkey, IfWinActive, ahk_exe Evernote.exe                           ; 针对Evernote 按Ctrl+D自动在光标处添加日期
    Hotkey, ^D, EvernoteDate
    
    Hotkey, IfWinActive, ahk_exe RAPTW.exe                              ; 如果正在使用RAPT,鼠标中间激活PT Tools
    Hotkey, ~MButton, RunPTTools
    Hotkey, IfWinActive
}

RunPTTools()                                                            ; 如果正在使用RAPT,鼠标中间激活PT Tools
{
    IfWinNotExist, PT Tools
        Run % A_ScriptDir "\PTTools.ahk"
    else IfWinNotActive, PT Tools
        WinActivate
}

RenameWithDate()                                                        ; 针对所有设定好的程序 按Ctrl+D自动在文件(夹)名之后添加日期
{
    ControlGetFocus, CurrCtrl, A                                        ; 获取当前激活的窗口中的聚焦的控件名称
    if (InStr(CurrCtrl, "Edit") or InStr(CurrCtrl, "Scintilla"))        ; 如果当前激活的控件为Edit类或者Scintilla1(Notepad2),则Ctrl+D功能生效
        NameAddDate("FileListMangr", CurrCtrl)
    Else
        SendInput ^D
}

LineEndAddDate()                                                        ; 针对TC File Comment对话框　按Ctrl+D自动在备注文字之后添加日期
{
    SendInput {End}
    Sleep, 10
    SendInput {Space}- %A_DD%.%A_MM%.%A_YYYY%
    Log.Msg("AddDateAtEnd, Add= - " A_DD "." A_MM "." A_YYYY)
}

EvernoteDate()                                                          ; 针对Evernote 按Ctrl+D自动在光标处添加日期
{
    SendInput {Space}- %A_DD%.%A_MM%.%A_YYYY%
    Log.Msg("EvernoteDate, Add= - " A_DD "." A_MM "." A_YYYY)
}

NameAddDate(WinName, CurrCtrl, isFile:= True)                           ; 在文件（夹）名编辑框中添加日期,CurrCtrl为当前控件(名称编辑框Edit),isFile是可选参数,默认为真
{
    ControlGetText, EditCtrlText, %CurrCtrl%, A
    SplitPath, % EditCtrlText, fileName, fileDir, fileExt, nameNoExt
    
    if (isFile && fileExt!="" && StrLen(fileExt)<5 && !RegExMatch(fileExt,"^\d+$")) ; 如果是文件,而且有真实文件后缀名,才加日期在后缀名之前, another way is use if fileExt in %TrgExtList% but can not check isFile at the same time
    {
        NameWithDate = %nameNoExt% - %A_DD%.%A_MM%.%A_YYYY%.%fileExt%
    }
    else
    {
        NameWithDate = %EditCtrlText% - %A_DD%.%A_MM%.%A_YYYY%
    }
    ControlClick, %CurrCtrl%, A
    ControlSetText, %CurrCtrl%, %NameWithDate%, A
    Sleep,10
    SendInput {End}
    Log.Msg(WinName ", RenameWithDate=" NameWithDate)
}

;============================================================
; Options / Settings Library
Options(Arg := "", ActTab := 1)                                         ; 1st parameter is to avoid menu like [Option `tF2] disturb ActTab
{
    Global                                                              ; Assume-global mode
    Log.Msg("Loading options window...Arg=" Arg ", ActTab=" ActTab)
    
    Gui, Setting:New, -SysMenu, %g_OptionsWinName%                      ;-SysMenu: omit the system menu and icon in the window's upper left corner
    Gui, Setting:Font, s9, Segoe UI
    Gui, Setting:Margin, 5, 5
    Gui, Setting:Add, Tab3,xm ym vCurrTab Choose%ActTab% -Wrap, General|Index|GUI|Command|Hotkey|Plugins|Help

    Gui, Setting:Tab, 1                                                 ; Config Tab
    Gui, Setting:Add, GroupBox, w500 h420, General Settings
    Gui, Setting:Add, CheckBox, xp+10 yp+25 vg_AutoStartup checked%g_AutoStartup%, Startup with Windows
    Gui, Setting:Add, CheckBox, xp+250 yp vg_EnableSendTo checked%g_EnableSendTo%, Enable SendTo Menu
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_InStartMenu checked%g_InStartMenu%, Enable Start Menu
    Gui, Setting:Add, CheckBox, xp+250 yp vg_AutoRank checked%g_AutoRank%, Enable Auto-Ranking
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_HideOnDeactivate checked%g_HideOnDeactivate%, Close on Lose Focus
    Gui, Setting:Add, CheckBox, xp+250 yp vg_AlwaysOnTop checked%g_AlwaysOnTop%, Window Always-On-Top
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_EscClearInput checked%g_EscClearInput%, Esc to Clear Input
    Gui, Setting:Add, CheckBox, xp+250 yp vg_KeepInputText checked%g_KeepInputText%, Keep Input on Close
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_ShowIcon checked%g_ShowIcon%, Show Icon in Command List
    Gui, Setting:Add, CheckBox, xp+250 yp vg_SendToGetLnk checked%g_SendToGetLnk%, SendTo Retrieves Lnk Target
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_SaveHistory checked%g_SaveHistory%, Enable Command History
    Gui, Setting:Add, CheckBox, xp+250 yp vg_isLogging checked%g_isLogging%, Enable Logging
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_SearchFullPath checked%g_SearchFullPath%, Search Full Path
    Gui, Setting:Add, CheckBox, xp+250 yp vg_EnableCapsLockIME checked%g_EnableCapsLockIME%, Enable CapsLock Switch IME
    Gui, Setting:Add, CheckBox, xp-250 yp+30, #Reserved
    Gui, Setting:Add, CheckBox, xp+250 yp, #Reserved
    Gui, Setting:Add, CheckBox, xp-250 yp+30, #Reserved
    Gui, Setting:Add, CheckBox, xp+250 yp, #Reserved
    Gui, Setting:Add, Text, xp-250 yp+40, Text Editor (eg. Notepad2): 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_Editor, %g_Editor%
    Gui, Setting:Add, Text, xp-150 yp+40, Everything.exe Path: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_Everything, %g_Everything%
    Gui, Setting:Add, Text, xp-150 yp+40, Total Commander Path: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_TCPath, %g_TCPath%
    
    Gui, Setting:Tab, 2                                                 ; Index Tab
    Gui, Setting:Add, GroupBox, w500 h420, Index Options
    Gui, Setting:Add, Text, xp+10 yp+40, Index Locations: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_IndexDir, %g_IndexDir%
    Gui, Setting:Add, Text, xp-150 yp+40, Index File Type: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_IndexFileType, %g_IndexFileType%
    Gui, Setting:Add, Text, xp-150 yp+40, Index File Exclude: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_IndexExclude, %g_IndexExclude%
    Gui, Setting:Add, Text, xp-150 yp+40, HistorySize: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_HistorySize, %g_HistorySize%

    Gui, Setting:Tab, 3                                                 ; GUI Tab
    Gui, Setting:Add, GroupBox, w500 h420, GUI Details
    Gui, Setting:Add, CheckBox, xp+10 yp+25 vg_HideTitle checked%g_HideTitle%, Hide Title Bar
    Gui, Setting:Add, CheckBox, xp+250 yp vg_ShowTrayIcon checked%g_ShowTrayIcon%, Show Tray Icon
    Gui, Setting:Add, CheckBox, xp-250 yp+30 vg_HideCol2 checked%g_HideCol2%, Hide 2nd column
    Gui, Setting:Add, CheckBox, xp+250 yp vg_LVGrid checked%g_LVGrid%, Grid in command list
    Gui, Setting:Add, Text, xp-250 yp+40 , Display Rows (1-9): 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_DisplayRows, %g_DisplayRows%
    Gui, Setting:Add, Text, xp+100 yp+5, 3rd column width: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_Col3Width, %g_Col3Width%
    Gui, Setting:Add, Text, xp-400 yp+40, 4th column width: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_Col4Width, %g_Col4Width%
    Gui, Setting:Add, Text, xp+100 yp+5, Font Name: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_FontName, %g_FontName%
    Gui, Setting:Add, Text, xp-400 yp+40, Font Size: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_FontSize, %g_FontSize%
    Gui, Setting:Add, Text, xp+100 yp+5, Font Color: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_FontColor, %g_FontColor%
    Gui, Setting:Add, Text, xp-400 yp+40, Window Width: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_WinWidth, %g_WinWidth%
    Gui, Setting:Add, Text, xp+100 yp+5, Edit Height: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_EditHeight, %g_EditHeight%
    Gui, Setting:Add, Text, xp-400 yp+40, Command List Height: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_ListHeight, %g_ListHeight%
    Gui, Setting:Add, Text, xp+100 yp+5, #
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80,
    Gui, Setting:Add, Text, xp-400 yp+40, Controls' Color:
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_CtrlColor, %g_CtrlColor%
    Gui, Setting:Add, Text, xp+100 yp+5, Window's Color:
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_WinColor, %g_WinColor%
    Gui, Setting:Add, Text, xp-400 yp+40, Background Picture: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_BackgroundPicture, %g_BackgroundPicture%
    Gui, Setting:Add, Text, xp+100 yp+5, #
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80,

    Gui, Setting:Tab, 5                                                 ; Hotkey Tab
    Gui, Setting:Add, GroupBox, w500 h85, Activate Hotkey:
    Gui, Setting:Add, Text, xp+10 yp+25 , Global Hotkey:
    Gui, Setting:Add, Hotkey, xp+150 yp-4 w330 vg_GlobalHotkey1, %g_GlobalHotkey1%
    Gui, Setting:Add, Text, xp-150 yp+35 , Alt. Global Hotkey:
    Gui, Setting:Add, Hotkey, xp+150 yp-4 w330 vg_GlobalHotkey2, %g_GlobalHotkey2%
    Gui, Setting:Add, GroupBox, xp-160 yp+40 w500 h55, Command Hotkey:
    Gui, Setting:Add, Text, xp+10 yp+25 , Execute Command:
    Gui, Setting:Add, CheckBox, xp+150 yp vg_RunCmdAlt checked%g_RunCmdAlt%, ALT +
    Gui, Setting:Add, Text, xp+60 yp, No.
    Gui, Setting:Add, Text, xp+45 yp, Select Command: 
    Gui, Setting:Add, Text, xp+130 yp, Ctrl + No.
    Gui, Setting:Add, GroupBox, xp-395 yp+40 w500 h130, Action Hotkey:
    Gui, Setting:Add, Text, xp+10 yp+25 , Hotkey 1: 
    Gui, Setting:Add, Hotkey, xp+150 yp-5 w80 vg_Hotkey1, %g_Hotkey1%
    Gui, Setting:Add, Text, xp+100 yp+5, Toggle Action: 
    Gui, Setting:Add, Edit, xp+110 yp-5 r1 w120 vg_Trigger1, %g_Trigger1%
    Gui, Setting:Add, Text, xp-360 yp+40 , Hotkey 2: 
    Gui, Setting:Add, Hotkey, xp+150 yp-5 w80 vg_Hotkey2, %g_Hotkey2%
    Gui, Setting:Add, Text, xp+100 yp+5, Toggle Action: 
    Gui, Setting:Add, Edit, xp+110 yp-5 r1 w120 vg_Trigger2, %g_Trigger2%
    Gui, Setting:Add, Text, xp-360 yp+40 , Hotkey 3: 
    Gui, Setting:Add, Hotkey, xp+150 yp-5 w80 vg_Hotkey3, %g_Hotkey3%
    Gui, Setting:Add, Text, xp+100 yp+5, Toggle Action: 
    Gui, Setting:Add, Edit, xp+110 yp-5 r1 w120 vg_Trigger3, %g_Trigger3%

    Gui, Setting:Tab, 6                                                 ; Plugins / Listary / Scheduler Tab
    Gui, Setting:Add, GroupBox, w500 h190, Listary Quick-Switch Options
    Gui, Setting:Add, Text, xp+10 yp+25 , File Manager Title: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_FileManager, %g_FileManager%
    Gui, Setting:Add, Text, xp-150 yp+40, Open/Save Dialog Title: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_DialogWin, %g_DialogWin%
    Gui, Setting:Add, Text, xp-150 yp+40, Exclude Windows Title: 
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w330 vg_ExcludeWin, %g_ExcludeWin%
    Gui, Setting:Add, Text, xp-150 yp+40, Switch to TC Dir: 
    Gui, Setting:Add, Hotkey, xp+150 yp-5 w80 vg_TotalCMDDir, %g_TotalCMDDir%
    Gui, Setting:Add, Text, xp+100 yp+5, Switch to Explorer Dir: 
    Gui, Setting:Add, Hotkey, xp+150 yp-5 w80 vg_ExplorerDir, %g_ExplorerDir%
    Gui, Setting:Add, CheckBox, xp-400 yp+40 vg_AutoSwitchDir checked%g_AutoSwitchDir%, Auto Switch Dir
    Gui, Setting:Add, GroupBox, xp-10 yp+35 w500 h55, Scheduler
    Gui, Setting:Add, CheckBox, xp+10 yp+25 vg_EnableScheduler checked%g_EnableScheduler%, Shutdown Scheduler
    Gui, Setting:Add, Text, xp+250 yp, Shutdown Time:
    Gui, Setting:Add, Edit, xp+150 yp-5 r1 w80 vg_ShutdownTime, %g_ShutdownTime%

    Gui, Setting:Tab, 7                                                 ; Help Tab
    AllCommands := LoadConfig("commands")
    Gui, Setting:Add, Edit, w500 h420 ReadOnly -WantReturn -Wrap,
    (Ltrim
    ALTRun
    An effective launcher for Windows, open source project
    https://github.com/zhugecaomao/ALTRun

    ------------------------------------------------------------------------
    Congraduations! You have run shortcut %g_RunCount% times by now! 
    
    shortcut list:-

    F1        		打开帮助页面
    F2        		打开配置选项
    F3        		编辑配置文件
    F4        		用户自定义索引列表
    F5        		编辑当前命令
    Shift + F1		显示置顶的按键提示
    Alt + F4		退出置顶的按键提示
    Enter   		执行当前命令
    Esc     		关闭窗口
    Alt +    		加每列行首字符执行
    Tab +    		再按每列行首字符执行
    Tab +    		再按 Shift + 行首字符 定位
    Win + J  		显示或隐藏窗口
    Ctrl + F		在输出结果中翻到下一页
    Ctrl + B		在输出结果中翻到上一页
    Ctrl + H		显示历史记录
    Ctrl + +		可增加当前功能的权重
    Ctrl + -		可减少当前功能的权重
    Ctrl + L		清除编辑框内容
    Ctrl + R		重新创建待搜索文件列表
    Ctrl + Q		重启
    Ctrl + D		用默认文件管理器打开当前命令所在目录
    Ctrl + S		显示并复制当前文件的完整路径
    Shift + Del		删除当前文件
    Ctrl + Del		删除当前命令
    Ctrl + I		移动光标当行首
    Ctrl + O		移动光标当行尾
    Input Web   	可直接输入 www 或 http 开头的网址
    ;        		以分号开头命令,用 ahk 运行
    :        		以冒号开头的命令,用 cmd 运行
    No Result		搜索无结果,回车用 ahk 运行
    Space       	输入空格后,搜索内容锁定
    ------------------------------------------------------------------------
    All Commands:-

    %AllCommands%
    )
    
    Gui, Setting:Tab                                                    ; 后续添加的控件将不属于前面那个选项卡控件

    Hotkey, %g_GlobalHotkey1%, Off
    Hotkey, %g_GlobalHotkey2%, Off

    Gui, Setting:Add, Button, Default x350 w80, OK
    Gui, Setting:Add, Button, xp+90 yp w80, Cancel
    Gui, Setting:Show,, %g_OptionsWinName%
}

;=============== 设置选项窗口 - 按钮动作 =================
SettingButtonOK()
{
    SaveConfig("main"), ALTRun_Reload()
}

SettingGuiEscape()
{
    SettingGuiClose()
}

SettingButtonCancel()
{
    SettingGuiClose()
}

SettingGuiClose()
{
    RemoveToolTip()
    Hotkey, %g_GlobalHotkey1%, On
    Hotkey, %g_GlobalHotkey2%, On
    Gui, Setting:Destroy
}

;=============================================================
; 加载主配置文件
;=============================================================
LoadConfig(Arg)
{
    Log.Msg("Loading configuration...Arg=" Arg)
    
    if (Arg = "config" or Arg = "initialize" or Arg = "all")
    {
        Loop Parse, KEYLIST_CONFIG, `,                                  ; Read config section
        {
            IniRead, g_%A_LoopField%, %g_IniFile%, %SEC_CONFIG%, %A_LoopField%, % g_%A_LoopField%
        }

        Loop Parse, KEYLIST_HOTKEY, `,                                  ; Read Hotkey section
        {
            IniRead, g_%A_LoopField%, %g_IniFile%, %SEC_HOTKEY%, %A_LoopField%, % g_%A_LoopField%
        }

        Loop Parse, KEYLIST_GUI, `,                                     ; Read GUI section
        {
            IniRead, g_%A_LoopField%, %g_IniFile%, %SEC_GUI%, %A_LoopField%, % g_%A_LoopField%
        }
        
        if (FileExist(g_BackgroundPicture))
        {
            g_BGPicture := g_BackgroundPicture
        }
        else
        {
            Extract_BG(A_Temp "\ALTRunBG.jpg")
            g_BGPicture := A_Temp "\ALTRunBG.jpg"
        }
    }

    if (Arg = "commands" or Arg = "initialize" or Arg = "all")          ; Built-in command initialize
    {
        IniRead, DFTCMDSEC, %g_IniFile%, %SEC_DFTCMD%
        if (DFTCMDSEC = "")
        {
            IniWrite, 
            (Ltrim
            ; Build-in Commands (High Priority, DO NOT Edit)
            ;
            Function | Help | ALTRun Help Index (F1)=100
            Function | ALTRun_Reload | ALTRun Reload=100
            Function | History | Command History=100
            Function | CmdMgr | New Command=100
            Function | UserCommandList | ALTRun User-defined command (F4)=100
            Function | ReindexFiles | Reindex search database=100
            Function | Everything | Search by Everything=100
            Function | Options | ALTRun Options Preference Settings (F2)=100
            Function | RunPTTools | PT Tools (AHK)=100
            File | %Temp%\ALTRun.log | ALTRun Log File=100
            Dir | A_ScriptDir | ALTRun Program Dir=100
            Dir | A_Startup | Current User Startup Dir=100
            Dir | A_StartupCommon | All User Startup Dir=100
            Dir | A_ProgramsCommon | Windowns Search.Index.Cortana Dir=100
            Function | AhkRun | Run Command use AutoHotkey Run=100
            Function | CmdRun | Run Command use CMD=100
            Function | RunAndDisplay | Run by CMD and display the result=100
            Function | ShowArg | Show Arguments=100
            Function | SearchOnGoogle | Search Clipboard or Input by Google=100
            Function | SearchOnBing | Search Clipboard or Input by Bing=100
            Function | ShowIp | Show IP Address=100
            Function | Clip | Show clipboard content=100
            Function | EmptyRecycle | Empty Recycle Bin=100
            Function | TurnMonitorOff | Turn off Monitor, Close Monitor=100
            Function | MuteVolume | Mute Volume=100
            ;
            ; Control Panel Commands
            ;
            Control | Control | Control Panel=66
            Control | wf.msc | Windows Defender Firewall with Advanced Security=66
            Control | Control intl.cpl | Region and Language Options=66
            Control | Control firewall.cpl | Windows Defender Firewall=66
            Control | Control access.cpl | Ease of Access Centre=66
            Control | Control appwiz.cpl | Programs and Features=66
            Control | Control sticpl.cpl | Scanners and Cameras=66
            Control | Control sysdm.cpl | System Properties=66
            Control | Control joy.cpl | Game Controllers=66
            Control | Control Mouse | Mouse Properties=66
            Control | Control desk.cpl | Display=66
            Control | Control mmsys.cpl | Sound=66
            Control | Control ncpa.cpl | Network Connections=66
            Control | Control powercfg.cpl | Power Options=66
            Control | Control timedate.cpl | Date and Time=66
            Control | Control admintools | Windows Tools=66
            Control | Control desktop | Personalisation=66
            Control | Control folders | File Explorer Options=66
            Control | Control fonts | Fonts=66
            Control | Control inetcpl.cpl,,4 | Internet Properties=66
            Control | Control printers | Devices and Printers=66
            Control | Control userpasswords | User Accounts=66
            Control | taskschd.msc | Task Scheduler=66
            Control | devmgmt.msc | Device Manager=66
            Control | eventvwr.msc | Event Viewer=66
            Control | compmgmt.msc | Computer Manager=66
            Control | taskmgr.exe | Task Manager=66
            Control | calc.exe | Calculator=66
            Control | mspaint.exe | Paint=66
            Control | cmd.exe | DOS / CMD=66
            Control | regedit.exe | Registry Editor=66
            Control | write.exe | Write=66
            Control | cleanmgr.exe | Disk Space Clean-up Manager=66
            Control | gpedit.msc | Group Policy=66
            Control | comexp.msc | Component Services=66
            Control | diskmgmt.msc | Disk Management=66
            Control | dxdiag.exe | Directx Diagnostic Tool=66
            Control | lusrmgr.msc | Local Users and Groups=66
            Control | msconfig.exe | System Configuration=66
            Control | perfmon.exe /Res | Resources Monitor=66
            Control | perfmon.exe | Performance Monitor=66
            Control | winver.exe | About Windows=66
            Control | services.msc | Services=66
            Control | netplwiz | User Accounts=66
            ), %g_IniFile%, %SEC_DFTCMD%
            IniRead, DFTCMDSEC, %g_IniFile%, %SEC_DFTCMD%
        }

        IniRead, USERCMDSEC, %g_IniFile%, %SEC_USERCMD%
        if (USERCMDSEC = "")
        {
            IniWrite, 
            (Ltrim
            ; User-Defined Commands (High priority, edit command as desired)
            ; Command type: File, Dir, CMD, Function, URL, Project, Tender
            ; Type | Command | Comments=Rank
            ;
            Dir | `%AppData`%\Microsoft\Windows\SendTo | Windows SendTo Dir=100
            Dir | `%OneDriveConsumer`% | OneDrive Personal Dir=100
            Dir | `%OneDriveCommercial`% | OneDrive Business Dir=100
            File | C:\OneDrive\Apps\TotalCMD64\Tools\Notepad2.exe=100
            CMD | ipconfig | Show IP Address(CMD type will run with cmd.exe, auto pause after run)=100
            URL | www.google.com | Google=100
            Project | Q:\DESIGN PROJECTS | Design Folder=100
            Tender | Q:\PROPOSALS & TENDERS | Tender Folder=100
            ), %g_IniFile%, %SEC_USERCMD%
            IniRead, USERCMDSEC, %g_IniFile%, %SEC_USERCMD%
        }

        IniRead, INDEXSEC, %g_IniFile%, %SEC_INDEX%                     ; Read whole section SEC_INDEX (Index database)
        if (INDEXSEC = "")
        {
            MsgBox, 4096, %g_WinName%, ALTRun initialize for first time running.`n`nAuto initialize in 30 seconds or click OK now., 30
            ReindexFiles()
        }
        Return DFTCMDSEC "`n" USERCMDSEC "`n" INDEXSEC
    }

    if (Arg = "fallbackcmd")
    {
        IniRead, FALLBACKCMDSEC, %g_IniFile%, %SEC_FALLBACK%
        if (FALLBACKCMDSEC = "")
        {
            IniWrite, 
            (Ltrim
            ;===========================================================
            ; Fallback Commands show when search result is empty
            ;
            Function | CmdMgr | New Command
            Function | Everything | Search by Everything
            Function | SearchOnGoogle | Search Clipboard or Input by Google
            Function | AhkRun | Run Command use AutoHotkey Run
            Function | CmdRun | Run Command use CMD
            Function | RunAndDisplay | Run by CMD and display the result
            Function | SearchOnBing | Search Clipboard or Input by Bing
            ), %g_IniFile%, %SEC_FALLBACK%
            IniRead, FALLBACKCMDSEC, %g_IniFile%, %SEC_FALLBACK%
        }
        Return %FALLBACKCMDSEC%
    }
    Return
}

;=============================================================
; 保存主配置文件
;=============================================================
SaveConfig(Arg)
{
    Log.Msg("Saving config...Arg=" Arg)
    if (Arg = "History")                                                ; 记录窗口激活次数RunCount,History,考虑效率,不能写入太频繁也不能写入太少
    {
        IniWrite, %g_RunCount%, %g_IniFile%, %SEC_CONFIG%, RunCount

        if (g_SaveHistory)
        {
            for index, element in g_HistoryCommands
            {
                IniWrite, %element%, %g_IniFile%, %SEC_HISTORY%, %index%
            }
        }
    }
    else if (Arg = "Main")
    {
        Gui, Setting:Submit                                             ; Submit and Hide, avoid delay feeling

        Loop Parse, KEYLIST_CONFIG, `,                                  ; Save Config Section settings
        {
            IniWrite, % g_%A_LoopField%, %g_IniFile%, %SEC_CONFIG%, %A_LoopField%
        }
        
        Loop Parse, KEYLIST_GUI, `,
        {
            IniWrite, % g_%A_LoopField%, %g_IniFile%, %SEC_GUI%, %A_LoopField%
        }
        
        Loop Parse, KEYLIST_HOTKEY, `,
        {
            IniWrite, % g_%A_LoopField%, %g_IniFile%, %SEC_HOTKEY%, %A_LoopField%
        }
    }
    Return
}

;=============================================================
; Language Library (Switch ENG on Activate, CapsLock switch IME)
; 为了让 Mac/Win 下的体验稍微一致些, 写了一个 ahk 脚本针对 CapsLock 键:
; 单击 切换输入法(本质是调用 win + sapce), 双击/长按 切换 CapsLock 状态
;=============================================================
switchCapsLockState() 
{
    state := GetKeyState("CapsLock", "T")
    nextState := !state
    SetCapsLockState % nextState
    
    return nextState
}

showTip(isOn) 
{
    title := isOn ? "CapsLock: ON" : "CapsLock: OFF"
    text := isOn ? "已打开" : "已关闭"

    TrayTip, %title%, %text%, 1, 16
    return 
}

ToggleAndShowTip()
{
    nextState :=switchCapsLockState()
    showTip(nextState)

    return
}

CapsLock::
    if (g_EnableCapsLockIME)
    {
        KeyWait, CapsLock, T0.3

        if (ErrorLevel) {                                               ; long click
            ToggleAndShowTip()
        } else {
            KeyWait, CapsLock, D T0.1

            if (ErrorLevel) {                                           ; single click
                SendInput #{Space} 
                ; 切换为中文时经常是中文输入法的英文模式,因为调用Win同时会调用Ctrl,Win10中设置：输入法模式右键-Key Configuration-Chinese/English mode switch-untick Ctrl+Space
                ; 对当前窗口激活下一输入法,会在中文（中文模式）,中文（英文模式）,英文循环切换
                ;DllCall("SendMessage", UInt, WinActive("A"), UInt, 80, UInt, 1, UInt, DllCall("ActivateKeyboardLayout", UInt, 1, UInt, 256))
            } else {                                                    ; double click
                ToggleAndShowTip()
            }
        }

        KeyWait, CapsLock
    }
    else
    {
        switchCapsLockState()
    }
Return

;=============================================================
; Resources File - Background picture
;=============================================================
Extract_BG(_Filename)
{
	Static Out_Data
    VarSetCapacity(TD, 13026)
	TD := "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"

    VarSetCapacity(Out_Data, Bytes := 4754, 0)
    DllCall("Crypt32.dll\CryptStringToBinary" "W", "Ptr", &TD, "UInt", 0, "UInt", 1, "Ptr", &Out_Data, "UIntP", Bytes, "Int", 0, "Int", 0, "CDECL Int")
	
	IfExist, %_Filename%
		FileDelete, %_Filename%
	
	h := DllCall("CreateFile", "Ptr", &_Filename, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
	, DllCall("WriteFile", "Ptr", h, "Ptr", &Out_Data, "UInt", 4754, "UInt", 0, "UInt", 0)
	, DllCall("CloseHandle", "Ptr", h)
}

;=============================================================
; Some Built-in Functions
;=============================================================
CmdRun()
{
    global
    RunWithCmd(Arg)
}

AhkRun()
{
    global
    Run, %Arg%
}

ShowArg()
{
    args := StrSplit(Arg, " ")
    result := "Function | Total " args.Length() " Args"

    for index, argument in args
    {
        result .= "`nFunction | No. " index " argument is: | " argument
    }

    ListResult(result, true, false)
}

RunAndDisplay()
{
    ListResult(GetCmdOutput(Arg), true, false)
}

Clip()
{
    ListResult("Display | Clipboard content length is " StrLen(clipboard) ", content is : | " clipboard, true, false)
}

TurnMonitorOff()                                                        ; 关闭显示器:
{
    SendMessage, 0x112, 0xF170, 2,, Program Manager                     ; 0x112 is WM_SYSCOMMAND, 0xF170 is SC_MONITORPOWER, 使用 -1 代替 2 来打开显示器, 使用 1 代替 2 来激活显示器的节能模式.
}

EmptyRecycle()
{
    MsgBox, 4, %g_WinName%, Do you really want to empty the Recycle Bin?
    IfMsgBox Yes
    {
        FileRecycleEmpty,
    }
}

MuteVolume()
{
    SoundSet, MUTE
}

ShowIp()
{    
    MsgBox, 64, %g_WinName%, IP 1 = %A_IPAddress1% `nIP 2 = %A_IPAddress2%`nIP 3 = %A_IPAddress3%
}

SearchOnGoogle()
{
    global
    word := Arg == "" ? clipboard : Arg
    Run, https://www.google.com/search?q=%word%&newwindow=1
}

SearchOnBing()
{
    global
    word := Arg == "" ? clipboard : Arg
    Run, http://cn.bing.com/search?q=%word%
}

Everything()
{
    Run, %g_Everything% -s "%Arg%",, UseErrorLevel
    if ErrorLevel
        MsgBox, % "Everything software not found.`n`nPlease check ALTRun setting and Everything program file."
}

;=======================================================================
; Library - Eval
;=======================================================================

xe := 2.718281828459045, xpi := 3.141592653589793      ; referenced as "e", "pi"
xinch := 2.54, xfoot := 30.48, xmile := 1.609344       ; [cm], [cm], [Km]
xounce := 0.02841, xpint := 0.5682, xgallon := 4.54609 ; liters
xoz := 28.35, xlb := 453.59237                         ; gramms

/* -test cases
MsgBox % Eval("1e1")                                               ; 10
MsgBox % Eval("0x1E")                                              ; 30
MsgBox % Eval("ToBin(35)")                                         ; 100011
MsgBox % Eval("$b 35")                                             ; 0100011
MsgBox % Eval("'10010")                                            ; -14
MsgBox % Eval("2>3 ? 9 : 7")                                       ; 7
MsgBox % Eval("$2E 1e3 -50.0e+0 + 100.e-1")                        ; 9.60E+002
MsgBox % Eval("fact(x) := x < 2 ? 1 : x*fact(x-1); fact(5)")       ; 120
MsgBox % Eval("f(ab):=sqrt(ab)/ab; y:=f(2); ff(y):=y*(y-1)/2/x; x := 2; y+ff(3)/f(16)") ; 6.70711
MsgBox % Eval("x := qq:1; x := 5*x; y := x+1")                     ; 6 [if y empty, x := 1...]
MsgBox % Eval("x:=-!0; x<0 ? 2*x : sqrt(x)")                       ; -2
MsgBox % Eval("tan(atan(atan(tan(1))))-exp(sqrt(1))")              ; -1.71828
MsgBox % Eval("---2+++9 + ~-2 --1 -2*-3")                          ; 15
MsgBox % Eval("x1:=1; f1:=sin(x1)/x1; y:=2; f2:=sin(y)/y; f1/f2")  ; 1.85082
MsgBox % Eval("Round(fac(10)/fac(5)**2) - (10 choose 5) + Fib(8)") ; 21
MsgBox % Eval("1 min-1 min-2 min 2")                               ; -2
MsgBox % Eval("(-1>>1<=9 && 3>2)<<2>>1")                           ; 2
MsgBox % Eval("(1 = 1) + (2<>3 || 2 < 1) + (9>=-1 && 3>2)")        ; 3
MsgBox % Eval("$b6 -21/3")                                         ; 111001
MsgBox % Eval("$b ('1001 << 5) | '01000")                          ; 100101000
MsgBox % Eval("$0 194*lb/1000")                                    ; 88 [Kg]
MsgBox % Eval("$x ~0xfffffff0 & 7 | 0x100 << 2")                   ; 0x407
MsgBox % Eval("- 1 * (+pi -((3%5))) +pi+ 1-2 + e-ROUND(abs(sqrt(floor(2)))**2)-e+pi $9") ; 3.141592654
MsgBox % Eval("(20+4 GCD abs(2**4)) + (9 GCD (6 CHOOSE 2))")       ; 11
t := A_TickCount
Loop 1000
   r := Eval("x:=" A_Index/1000 ";atan(x)-exp(sqrt(x))")           ; simulated plot
t := A_TickCount - t
MsgBox Result = %r%`nTime = %t%                                    ; -1.93288: ~400 ms [on Inspiron 9300]
*/

^#-::                                  ; Replace selection or `expression with result
^#=::                                  ; Append result to selection or `expression
   ClipBoard =
   SendInput ^c                        ; copy selection
   ClipWait 0.5
   If (ErrorLevel) {
      SendInput +{HOME}^c              ; copy, keep selection to overwrite (^x for some apps)
      ClipWait 1
      IfEqual ErrorLevel,1, Return
      If RegExMatch(ClipBoard, "(.*)(``)(.*)", y)
         SendInput %  "{RAW}" y1 . (A_ThisHotKey="^#=" ? y3 . " = "  : "") . Eval(y3)
   } Else
      SendInput % "{RAW}" . (A_ThisHotKey="^#=" ? ClipBoard . " = "  : "") . Eval(ClipBoard)
Return

Eval(x) {                              ; non-recursive PRE/POST PROCESSING: I/O forms, numbers, ops, ";"
   Local FORM, FormF, FormI, i, W, y, y1, y2, y3, y4
   FormI := A_FormatInteger, FormF := A_FormatFloat

   SetFormat Integer, D                ; decimal intermediate results!
   RegExMatch(x, "\$(b|h|x|)(\d*[eEgG]?)", y)
   FORM := y1, W := y2                 ; HeX, Bin, .{digits} output format
   SetFormat FLOAT, 0.16e              ; Full intermediate float precision
   StringReplace x, x, %y%             ; remove $..
   Loop
      If RegExMatch(x, "i)(.*)(0x[a-f\d]*)(.*)", y)
         x := y1 . y2+0 . y3           ; convert hex numbers to decimal
      Else Break
   Loop
      If RegExMatch(x, "(.*)'([01]*)(.*)", y)
         x := y1 . FromBin(y2) . y3    ; convert binary numbers to decimal: sign = first bit
      Else Break
   x := RegExReplace(x,"(^|[^.\d])(\d+)(e|E)","$1$2.$3")                ; add missing '.' before E (1e3 -> 1.e3)
   x := RegExReplace(x,"(\d*\.\d*|\d)([eE][+-]?\d+)","‘$1$2’")          ; literal scientific numbers between ‘ and ’ chars

   StringReplace x, x,`%, \, All            ; %  -> \ (= MOD)
   StringReplace x, x, **,@, All            ; ** -> @ for easier process
   StringReplace x, x, ^,@, All             ; ^ -> @ for easier process
   StringReplace x, x, +, ±, All            ; ± is addition
   x := RegExReplace(x,"(‘[^’]*)±","$1+")   ; ...not inside literal numbers
   StringReplace x, x, -, ¬, All            ; ¬ is subtraction
   x := RegExReplace(x,"(‘[^’]*)¬","$1-")   ; ...not inside literal numbers

   Loop Parse, x, `;
      y := Eval1(A_LoopField)          ; work on pre-processed sub expressions
                                       ; return result of last sub-expression (numeric)
   If FORM = b                         ; convert output to binary
      y := W ? ToBinW(Round(y),W) : ToBin(Round(y))
   Else If (FORM="h" or FORM="x") {
      SetFormat Integer, Hex           ; convert output to hex
      y := Round(y) + 0
   }
   Else {
      W := W="" ? "0.6g" : "0." . W    ; Set output form, Default = 6 decimal places
      SetFormat FLOAT, %W%
      y += 0.0
   }
   SetFormat Integer, %FormI%          ; restore original formats
   SetFormat FLOAT,   %FormF%
   Return y
}

Eval1(x) {                             ; recursive PREPROCESSING of :=, vars, (..) [decimal, no ";"]
   Local i, y, y1, y2, y3
   If RegExMatch(x, "(\S*?)\((.*?)\)\s*:=\s*(.*)", y) {                 ; save function definition: f(x) := expr
      f%y1%__X := y2, f%y1%__F := y3
      Return
   }
                                       ; execute leftmost ":=" operator of a := b := ...
   If RegExMatch(x, "(\S*?)\s*:=\s*(.*)", y) {
      y := "x" . y1                    ; user vars internally start with x to avoid name conflicts
      Return %y% := Eval1(y2)
   }
                                       ; here: no variable to the left of last ":="
   x := RegExReplace(x,"([\)’.\w]\s+|[\)’])([a-z_A-Z]+)","$1«$2»")  ; op -> «op»

   x := RegExReplace(x,"\s+")          ; remove spaces, tabs, newlines

   x := RegExReplace(x,"([a-z_A-Z]\w*)\(","'$1'(") ; func( -> 'func'( to avoid atan|tan conflicts

   x := RegExReplace(x,"([a-z_A-Z]\w*)([^\w'»’]|$)","%x$1%$2") ; VAR -> %xVAR%
   x := RegExReplace(x,"(‘[^’]*)%x[eE]%","$1e") ; in numbers %xe% -> e
   x := RegExReplace(x,"‘|’")          ; no more need for number markers
   Transform x, Deref, %x%             ; dereference all right-hand-side %var%-s

   Loop {                              ; find last innermost (..)
      If RegExMatch(x, "(.*)\(([^\(\)]*)\)(.*)", y)
         x := y1 . Eval@(y2) . y3      ; replace (x) with value of x
      Else Break
   }
   Return Eval@(x)
}

Eval@(x) {                             ; EVALUATE PRE-PROCESSED EXPRESSIONS [decimal, NO space, vars, (..), ";", ":="]
   Local i, y, y1, y2, y3, y4

   If x is number                      ; no more operators left
      Return x
                                       ; execute rightmost ?,: operator
   RegExMatch(x, "(.*)(\?|:)(.*)", y)
   IfEqual y2,?,  Return Eval@(y1) ? Eval@(y3) : ""
   IfEqual y2,:,  Return ((y := Eval@(y1)) = "" ? Eval@(y3) : y)

   StringGetPos i, x, ||, R            ; execute rightmost || operator
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) || Eval@(SubStr(x,3+i))
   StringGetPos i, x, &&, R            ; execute rightmost && operator
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) && Eval@(SubStr(x,3+i))
                                       ; execute rightmost =, <> operator
   RegExMatch(x, "(.*)(?<![\<\>])(\<\>|=)(.*)", y)
   IfEqual y2,=,  Return Eval@(y1) =  Eval@(y3)
   IfEqual y2,<>, Return Eval@(y1) <> Eval@(y3)
                                       ; execute rightmost <,>,<=,>= operator
   RegExMatch(x, "(.*)(?<![\<\>])(\<=?|\>=?)(?![\<\>])(.*)", y)
   IfEqual y2,<,  Return Eval@(y1) <  Eval@(y3)
   IfEqual y2,>,  Return Eval@(y1) >  Eval@(y3)
   IfEqual y2,<=, Return Eval@(y1) <= Eval@(y3)
   IfEqual y2,>=, Return Eval@(y1) >= Eval@(y3)
                                       ; execute rightmost user operator (low precedence)
   RegExMatch(x, "i)(.*)«(.*?)»(.*)", y)
   If IsFunc(y2)
      Return %y2%(Eval@(y1),Eval@(y3)) ; predefined relational ops

   StringGetPos i, x, |, R             ; execute rightmost | operator
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) | Eval@(SubStr(x,2+i))
   StringGetPos i, x, ^, R             ; execute rightmost ^ operator
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) ^ Eval@(SubStr(x,2+i))
   StringGetPos i, x, &, R             ; execute rightmost & operator
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) & Eval@(SubStr(x,2+i))
                                       ; execute rightmost <<, >> operator
   RegExMatch(x, "(.*)(\<\<|\>\>)(.*)", y)
   IfEqual y2,<<, Return Eval@(y1) << Eval@(y3)
   IfEqual y2,>>, Return Eval@(y1) >> Eval@(y3)
                                       ; execute rightmost +- (not unary) operator
   RegExMatch(x, "(.*[^!\~±¬\@\*/\\])(±|¬)(.*)", y) ; lower precedence ops already handled
   IfEqual y2,±,  Return Eval@(y1) + Eval@(y3)
   IfEqual y2,¬,  Return Eval@(y1) - Eval@(y3)
                                       ; execute rightmost */% operator
   RegExMatch(x, "(.*)(\*|/|\\)(.*)", y)
   IfEqual y2,*,  Return Eval@(y1) * Eval@(y3)
   IfEqual y2,/,  Return Eval@(y1) / Eval@(y3)
   IfEqual y2,\,  Return Mod(Eval@(y1),Eval@(y3))
                                       ; execute rightmost power
   StringGetPos i, x, @, R
   IfGreaterOrEqual i,0, Return Eval@(SubStr(x,1,i)) ** Eval@(SubStr(x,2+i))
                                       ; execute rightmost function, unary operator
   If !RegExMatch(x,"(.*)(!|±|¬|~|'(.*)')(.*)", y)
      Return x                         ; no more function (y1 <> "" only at multiple unaries: --+-)
   IfEqual y2,!,Return Eval@(y1 . !y4) ; unary !
   IfEqual y2,±,Return Eval@(y1 .  y4) ; unary +
   IfEqual y2,¬,Return Eval@(y1 . -y4) ; unary - (they behave like functions)
   IfEqual y2,~,Return Eval@(y1 . ~y4) ; unary ~
   If IsFunc(y3)
      Return Eval@(y1 . %y3%(y4))      ; built-in and predefined functions(y4)
   Return Eval@(y1 . Eval1(RegExReplace(f%y3%__F, f%y3%__X, y4))) ; LAST: user defined functions
}

ToBin(n) {      ; Binary representation of n. 1st bit is SIGN: -8 -> 1000, -1 -> 1, 0 -> 0, 8 -> 01000
   if (n == "")
   {
       return 0
   }
   Return n=0||n=-1 ? -n : ToBin(n>>1) . n&1
}
ToBinW(n,W=8) { ; LS W-bits of Binary representation of n
   Loop %W%     ; Recursive (slower): Return W=1 ? n&1 : ToBinW(n>>1,W-1) . n&1
      b := n&1 . b, n >>= 1
   Return b
}
FromBin(bits) { ; Number converted from the binary "bits" string, 1st bit is SIGN
   n = 0
   Loop Parse, bits
      n += n + A_LoopField
   Return n - (SubStr(bits,1,1)<<StrLen(bits))
}

Sgn(x) {
   Return (x>0)-(x<0)
}

GCD(a,b) {      ; Euclidean GCD
   Return b=0 ? Abs(a) : GCD(b, mod(a,b))
}
Choose(n,k) {   ; Binomial coefficient
   p := 1, i := 0, k := k < n-k ? k : n-k
   Loop %k%                   ; Recursive (slower): Return k = 0 ? 1 : Choose(n-1,k-1)*n//k
      p *= (n-i)/(k-i), i+=1  ; FOR INTEGERS: p *= n-i, p //= ++i
   Return Round(p)
}

Fib(n) {        ; n-th Fibonacci number (n < 0 OK, iterative to avoid globals)
   a := 0, b := 1
   Loop % abs(n)-1
      c := b, b += a, a := c
   Return n=0 ? 0 : n>0 || n&1 ? b : -b
}
fac(n) {        ; n!
   Return n<2 ? 1 : n*fac(n-1)
}

;=======================================================================
; Library - Logger
; Logs := New Logger("Logger.log")
; Logs.Debug(A_LineNumber, "Test Log Message")
;=======================================================================
Class Logger
{
    __New(filename)
    {
        this.filename := filename
        this.enable := True

        if (!g_isLogging)                                               ; If disable logging, clean up logs
        {
            this.enable := False
            FileDelete, %g_LogFile%
            Return
        }
    }

    Msg(Msg)
    {
        if (this.enable)
        {
            FileAppend, % "[" A_Now "] " Msg "`n", % this.filename
        }
    }
}