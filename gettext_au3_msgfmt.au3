#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Martin Stut

	Script Function:
	Main program.
	generate gettext_au3_table.au3 from all ??.po files (language code must have exactly two characters) in the current directory
	gettext_au3_table.au3 then needs to be included in the runtime library.
	This is roughly the equivalent of C/Unix gettext's msgfmt.exe.

#ce ----------------------------------------------------------------------------
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
AutoItSetOption("MustDeclareVars", 1)
Global $apptitle = "gettext_au3_msgfmt gettext generator"
Global $sAu3OutputFileName = "gettext_au3_gettext.au3"
Func WalkThroughPoFiles() ; add the large switch statement to the output code
	Local $sGlobPattern = "??.po" ; this assumes that all language codes are exactly two characters
	Local $hPoSearch = FileFindFirstFile($sGlobPattern)
	; Check if the search was successful, if not display a message and return False.
	If $hPoSearch = -1 Then
		MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in WalkThroughPoFiles: No .po files found. No files matched the search pattern %s.", $sGlobPattern))
		Return False
	EndIf
	Local $sPoFileName = "" ; Assign a Local variable the empty string which will contain the files names found.
	While 1
		Local $sPoFileName = FileFindNextFile($hPoSearch)
		If @error Then ExitLoop ; If there is no more file matching the search. This is a normal event.
		AddSwitchGroupToOutput($sPoFileName)
	WEnd
	FileClose($hPoSearch) ; close file search handle
	Return True
EndFunc   ;==>WalkThroughPoFiles
Func AddSwitchGroupToOutput($sPoFileName) ; add the language defined by the file $sPoFileName to the big Switch statement
	; Return false and MsgBox if trouble
	Local $aLangName = StringSplit($sPoFileName, ".")
	If @error Then
		MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in AddSwitchGroupToOutput: StringSplit failed on filename %s which should have been [language].po.", $sPoFileName))
		Return False
	EndIf
	Local $sLangName = $aLangName[1]
	FileWriteLine($sAu3OutputFileName, '        Case "' & $sLangName & '" ; result of processing ' & $sPoFileName)
	FileWriteLine($sAu3OutputFileName, "            Switch $sSourceText")
	Local $hPoFile = FileOpen($sPoFileName)
	If $hPoFile = -1 Then
		MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in AddSwitchGroupToOutput: Can't open .po files %s .", $sPoFileName))
		Return False
	EndIf
	ParsePoFile($hPoFile, $sLangName)
	FileClose($hPoFile)
	FileWriteLine($sAu3OutputFileName, "            EndSwitch")
EndFunc   ;==>AddSwitchGroupToOutput
Func ParsePoFile($hPoFile, $sLangName) ;loop through lines in .po file pointed to by $hPoFile (freshly opened)
	; Return False and MsgBox in case of trouble
	; Parameter $sLangName is only needed for messages about missing translations
	; State Machine Logic:
	; 0 : outside segment, i.E. before first msgid or after having processed msgstr
	; 1 : after processing msgid
	; 2 : after processing msgstr
	; inintialize state machine
	Local $iState = 0
	Local $sSourceText = ""
	Local $sTranslatedText = ""
	; loop through lines
	Local $iLineNumber = 0
	While True
		$iLineNumber += 1
		Local $sNextLine = FileReadLine($hPoFile)
		Local $iTmpError = @error
		If $iTmpError = -1 Then ExitLoop ; regular EOF
		If $iTmpError <> 0 Then
			MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: FileReadLine of %s.po file failed in line number %d.", $sLangName, $iLineNumber))
			Return False
		EndIf
		; split line, determine $sLineType and $sLineValue
		Local $sStrippedLine = StringStripWS($sNextLine, $STR_STRIPLEADING + $STR_STRIPTRAILING)
		Local $sLineType = "ignore"
		Local $sLineValue = ""
		If StringLeft($sStrippedLine, 6) = "msgid " Then
			$sLineType = "msgid"
			$sLineValue = StringStripWS(StringMid($sStrippedLine, 7), $STR_STRIPLEADING + $STR_STRIPTRAILING)
		ElseIf StringLeft($sStrippedLine, 7) = "msgstr " Then
			$sLineType = "msgstr"
			$sLineValue = StringStripWS(StringMid($sStrippedLine, 8), $STR_STRIPLEADING + $STR_STRIPTRAILING)
		Else
			$sLineType = "ignore"
			Local $sLineValue = ""
		EndIf
		; process line according to state machine
		Switch $sLineType
			Case "msgid"
				If $iState <> 0 Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'msgid' encountered while in State %d in %s.po line number %d.", $iState, $sLangName, $iLineNumber))
				EndIf
				If StringLeft($sLineValue,1) <> '"' Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgid does not start with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLangName, $iLineNumber))
				EndIf
				If StringRight($sLineValue,1) <> '"' Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgid does not end with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLangName, $iLineNumber))
				EndIf
				$sSourceText = $sLineValue
				$iState = 1
			Case "msgstr"
				If $iState <> 1 Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'msgstr' encountered while in State %d in %s.po line number %d.", $iState, $sLangName, $iLineNumber))
				EndIf
				If StringLeft($sLineValue,1) <> '"' Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgstr does not start with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLangName, $iLineNumber))
				EndIf
				If StringRight($sLineValue,1) <> '"' Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgstr does not end with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLangName, $iLineNumber))
				EndIf
				$sTranslatedText = $sLineValue
				If ($sSourceText > '""') Then
					If ($sTranslatedText > '""') Then
						FileWriteLine($sAu3OutputFileName, "                Case " & $sSourceText)
						FileWriteLine($sAu3OutputFileName, '                    Return ' & $sTranslatedText)
					Else
						MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: Missing translation for source text %s in %s.po line number %d.", $sSourceText, $sLangName, $iLineNumber))
					EndIf
				Else	; SourceText trivially short. nothing to do. This occurs when processing the header
				EndIf
				Local $sSourceText = ""
				Local $sTranslatedText = ""
				$iState = 2
			Case "ignore"
				If $iState = 2 Then
					$iState = 0
				ElseIf $iState <> 0 Then
					MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'ignore' encountered while in State %d in line number %d.", $iState, $iLineNumber))
				EndIf
			Case Else
				MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: illegal LineType %s in line number %d.", $sLineType, $iLineNumber))
		EndSwitch
	WEnd
EndFunc   ;==>ParsePoFile
#Region Main Program
Global $apptitle = "msgfmt gettext generator"
FileDelete($sAu3OutputFileName) ; remove leftover from previous run
FileWriteLine($sAu3OutputFileName, "; DO NOT EDIT. Generated by msgfmt.au3 at " & @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & ":" & @MIN & ":" & @SEC)
FileWriteLine($sAu3OutputFileName, "#include-once")
FileWriteLine($sAu3OutputFileName, "Func gettext_au3_runtime(Const $sSourceText, Const $lang)")
FileWriteLine($sAu3OutputFileName, "    Switch $lang")
WalkThroughPoFiles()
FileWriteLine($sAu3OutputFileName, "    EndSwitch")
FileWriteLine($sAu3OutputFileName, "    ; if execution gets here, no lang/text pair has matched.")
FileWriteLine($sAu3OutputFileName, "    Return '*' & $sSourceText ; * signifying 'translation missing'")
FileWriteLine($sAu3OutputFileName, "EndFunc")
Exit
#EndRegion Main Program
