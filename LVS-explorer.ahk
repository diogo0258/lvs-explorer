/*
Shows the items of a given folder (first parameter) in a searchable listview.

Press:
- Enter with a folder selected to explore it in listview; with a file selected, open it.
- Shift+Enter with a folder selected to open it in explorer.
- Ctrl+e to open explorer in folder being searched, with the selected filename also selected in explorer.
- Alt+Up to go up one dir.
*/

#NoEnv
#SingleInstance, force

	if %0%
		CurrentFolder = %1%
	else
		CurrentFolder := ""

	if CurrentFolder and IsFolder(CurrentFolder)
	{
		if (SubStr(CurrentFolder, 0, 1) != "\")  ; add trailing \ if not present
			CurrentFolder .= "\"
	}

	GuiHwnd := LVS_Init("Callback", "Index|Filename", 2, 2, True, False)

	Hotkey, IfWinActive, ahk_id %GuiHwnd%
		Hotkey, ^e, OpenCurrentFolderInExplorer, on
		Hotkey, !Up, LoadFolderAbove, on
	Hotkey, IfWinActive
	
	LoadFolder(CurrentFolder)
return


OpenCurrentFolderInExplorer:
	OpenExplorerInFolder(CurrentFolder, LVS_Selected())
	GoSub, Fin
return

LoadFolderAbove:
	LoadFolder(FolderAbove(CurrentFolder))
return



LoadFolder(Folder) {
	global CurrentFolder
	
	CurrentFolder := Folder
	FileList := GetFileList(Folder)
	
	LVS_SetBottomText(CurrentFolder)
	LVS_SetList(FileList, "|")
	LVS_UpdateColOptions()
	LVS_Show()
}


GetDriveList() {
	DriveGet, DriveList, List

	FileList := ""
	Loop, Parse, DriveList
	{
		DriveGet, CurrentDriveLabel, Label, %A_LoopField%:
		if (CurrentDriveLabel = "")
			FileList .= A_Index . "|" . A_LoopField . ":\`n"
		else
			FileList .= A_Index . "|" . A_LoopField . ":\ [" . CurrentDriveLabel . "]`n"
	}
	StringTrimRight, FileList, FileList, 1  ; removes last `n
	return FileList
}


GetFileList(Folder := "") {
; returns a string with lines in the form %index%|%filename%. List starts with "0|..\", to go up one dir.
; lists directories first, then files.
; if Folder is not specified, return a list of available drives, in the form "%index%|C:\ [drivelabel]"
	if (Folder = "")
		return GetDriveList()

	if not IsFolder(Folder)
		return ""

	FileList := "0|..\`n"	  ; up
	i := 1

	Loop, % Folder . "*", 2	  ; First add folders only; var Folder should already have trailing "\"
	{
		FileList .= i . "|" . A_LoopFileName . "\`n"
		i++
	}

	Loop, % Folder . "*", 0	  ; Add files only
	{
		FileList .= i . "|" . A_LoopFileName . "`n"
		i++
	}

	StringTrimRight, FileList, FileList, 1  ; removes last `n
	
	return FileList
}


FolderAbove(Folder) {
	if (RegExMatch(Folder, "^[a-zA-Z]:\\?$"))  ; is drive's root
		Above := ""
	else
		Above := RegExReplace(Folder, "\\[^\\]+\\?$", "\")
	
	return Above
}


Callback(Selected, Escaped = False) {
; selected should be only one entry
	global CurrentFolder
	
	if (Escaped or Selected = "")
		GoSub, Fin
	
	ShiftPressed := GetKeyState("Shift") ? True : False  ; get this info early, key can be released during function
	
	if (CurrentFolder = "")  ; drive was selected
		NextFolder := RegExReplace(Selected, "(.*?)\s*\[.*?\]", "$1")
	
	else if (Selected = "..\")
		NextFolder := FolderAbove(CurrentFolder)
	
	else
	{
		Item := CurrentFolder . Selected
		if IsFolder(Item)
			NextFolder := Item
		else
		{
			RunFile(Item)
			GoSub, Fin
		}
	}
	
	CurrentFolder := NextFolder
	if (ShiftPressed)
		OpenExplorerInFolder(CurrentFolder)
	else
		LoadFolder(CurrentFolder)
	
	return 0
}


RunFile(file) {
	Run, "%file%"
}


OpenExplorerInFolder(Folder, FiletoSelect := "") {
	if ((FiletoSelect = "") or (FiletoSelect = "..\"))
		Run, % "explorer.exe """ Folder """"
	else
	  ; TODO: possible to open explorer with multiple files selected this way?
	  ; Not that simple. See https://stackoverflow.com/questions/9355/programmatically-select-multiple-files-in-windows-explorer
		Run, % "explorer.exe /select,""" Folder FiletoSelect """"
}


IsFolder(Path) {
	return InStr(FileExist(Path), "D") ? True : False
}


Fin:
; LVS_Hide()
ExitApp

#Include %A_ScriptDir%\LVS.ahk