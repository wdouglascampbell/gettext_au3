#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Martin Stut

	Script Function:
	Main program.
	generate gettext_au3_table.au3 from all *.po files in the current directory
	gettext_au3_table.au3 then needs to be included in the runtime library.
	This is roughly the equivalent of C/Unix gettext's msgfmt.exe.

#ce ----------------------------------------------------------------------------
#include <Array.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include "gettext_au3_language_codes.au3"
AutoItSetOption("MustDeclareVars", 1)
#pragma compile(Console, false)
Global $apptitle = "gettext_au3_msgfmt gettext generator"
Global $sAu3OutputFileName = "gettext_au3_gettext.au3"
Global $sLanguageList = "" ; list of languages that do have translations; will be filled by this program. Format e.g. "en,English|de,Deutsch"
; internal data structure
Global $aLanguageCodes[0] ;	List of language codes.
Global $aSourceStrings[0] ; List of source strings
Global $aTranslatedStrings[0][0] ; $aTranslatedStrings[$s][$l] contains the translation of $aSourceStrings[$s] into language $aLanguageCodes[$l]
Func getArrayIndex($sValue, ByRef $aList) ; return the index of $sValue within 1-D array $aList
	; if $sValue is not (yet) contained in $aList, add an element to $aList containing $sValue and return its index
	; the relationship value<->index will never be changed, so external applications can rely on this being constant
	; in case of error: MsgBox and Exit, so the calling environment does not need to handle error cases.
	; This is a helper function.
	; Calling this function is relatively expensive, always triggering an _ArraySearch
	Local $iSearchRes = _ArraySearch($aList, $sValue)
	Local $iSearchError = @error
	If $iSearchRes >= 0 Then
		Return $iSearchRes
	EndIf
	If ($iSearchError <> 6) And ($iSearchError <> 3) Then
		MsgBox(16, "getArrayIndex error", StringFormat("_ArraySearch($aList, '%s') returned @error %d.", $sValue, $iSearchError))
		Exit 1
	EndIf
	; when execution gets here, $sValue was not found in $aList, but there was no odd error
	; add $sValue to $aList
	Local $iAddRes = _ArrayAdd($aList, $sValue)
	If $iAddRes >= 0 Then Return $iAddRes
	; if execution gets here, there has been an odd error in _ArrayAdd
	Local $iAddError = @error
	MsgBox(16, "getArrayIndex error", StringFormat("_ArrayAdd($aList, %s) returned @error %d.", $sValue, $iAddError))
	Exit 1
EndFunc   ;==>getArrayIndex
Func getLangNumber($sLanguageCode) ; return index of $sLanguageCode within $aLanguageCodes[]
	; if it does not exist, add a new element to $aLanguageCodes[]
	Local Static $sLastLanguageCode = ""
	Local Static $iLastLanguageIndex = -1
	If $sLanguageCode = $sLastLanguageCode Then Return $iLastLanguageIndex
	$iLastLanguageIndex = getArrayIndex($sLanguageCode, $aLanguageCodes)
	$sLastLanguageCode = $sLanguageCode
	; check size of $aTranslatedStrings
	If $iLastLanguageIndex >= UBound($aTranslatedStrings, 2) Then
		ReDim $aTranslatedStrings[UBound($aTranslatedStrings, 1)][$iLastLanguageIndex + 1]
	EndIf
	Return $iLastLanguageIndex
EndFunc   ;==>getLangNumber
Func getStringIndex($sSourceString) ; return index of $sSourceString within $aSourceStrings[]
	; if it does not exist, add a new element to $aSourceStrings[]
	Local Static $sLastSourceString = ""
	Local Static $iLastStringIndex = -1
	If $sSourceString = $sLastSourceString Then Return $iLastStringIndex
	$iLastStringIndex = getArrayIndex($sSourceString, $aSourceStrings)
	$sLastSourceString = $sSourceString
	; check size of $aTranslatedStrings
	If $iLastStringIndex >= UBound($aTranslatedStrings, 1) Then
		ReDim $aTranslatedStrings[$iLastStringIndex + 1][UBound($aTranslatedStrings, 2)]
	EndIf
	Return $iLastStringIndex
EndFunc   ;==>getStringIndex
Func WalkThroughPoFiles() ; read all applicable .po files and fill the array structure with their content
	Local $sGlobPattern = "*.po" ; this assumes that all language codes are exactly two characters
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
		Local $aLangName = StringSplit($sPoFileName, ".")
		If @error Then
			MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in WalkThroughPoFiles: StringSplit failed on filename %s which should have been [language].po.", $sPoFileName))
			Exit 2
		EndIf
		Local $sLanguageCode = $aLangName[1]
		Local $hPoFile = FileOpen($sPoFileName)
		If $hPoFile = -1 Then
			MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in WalkThroughPoFiles: Can't open .po file %s .", $sPoFileName))
			Exit 2
		EndIf
		ParsePoFile($hPoFile, $sLanguageCode)
		FileClose($hPoFile)
	WEnd
	FileClose($hPoSearch) ; close file search handle
	Return True
EndFunc   ;==>WalkThroughPoFiles
Func ParsePoFile($hPoFile, $sLanguageCode) ; loop through lines in the single .po file pointed to by $hPoFile (freshly opened) and fill the arrays
	; Return False and MsgBox in case of trouble
	; Parameter $sLanguageCode is only needed for messages about missing translations
	; State Machine Logic:
	; 0 : outside segment, i.E. before first non-empty msgid or after having processed msgstr
	; 1 : after processing non-empty msgid
	; 2 : after processing msgstr after non-emtpy msgid
	; 3 : after processing emtpy msgid
	; 4 : after processing msgstr after emtpy msgid
	; inintialize state machine
	Local $iLanguageIndex = getLangNumber($sLanguageCode)
	Local $sMissingTranslations = ""
	Local $iState = 0
	Local $sSourceString = ""
	Local $sTranslatedString = ""
	; loop through lines
	Local $iLineNumber = 0
	While True
		$iLineNumber += 1
		Local $sNextLine = FileReadLine($hPoFile)
		Local $iTmpError = @error
		If $iTmpError = -1 Then ExitLoop ; regular EOF
		If $iTmpError <> 0 Then
			MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: FileReadLine of %s.po file failed in line number %d with error %d.", $sLanguageCode, $iLineNumber, $iTmpError))
			Return False
		EndIf
		; split line, determine $sLineType and $sLineValue
		Local $sStrippedLine = StringStripWS($sNextLine, $STR_STRIPLEADING + $STR_STRIPTRAILING)
		Local $aStrippedLine = StringSplit($sStrippedLine, " ")
		Local $sLineType = "ignore"
		Local $sLineValue = ""
		If StringLen($sStrippedLine) < 1 Then
			$sLineType = "ignore"
		ElseIf StringLeft($sStrippedLine, 1) = "#" Then
			$sLineType = "ignore"
		ElseIf StringLeft($sStrippedLine, 6) = "msgid " Then
			$sLineType = "msgid"
			$sLineValue = StringStripWS(StringMid($sStrippedLine, 7), $STR_STRIPLEADING + $STR_STRIPTRAILING)
		ElseIf StringLeft($sStrippedLine, 7) = "msgstr " Then
			$sLineType = "msgstr"
			$sLineValue = StringStripWS(StringMid($sStrippedLine, 8), $STR_STRIPLEADING + $STR_STRIPTRAILING)
		Else
			$sLineType = $aStrippedLine[1]
			Local $sLineValue = $sStrippedLine
		EndIf
		; process line according to state machine
		Switch $sLineType
			Case "msgid"
				Switch $iState
					Case 0
						If $sLineValue > '""' Then
							If StringLeft($sLineValue, 1) <> '"' Then
								MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgid does not start with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLanguageCode, $iLineNumber))
							EndIf
							If StringRight($sLineValue, 1) <> '"' Then
								MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgid does not end with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLanguageCode, $iLineNumber))
							EndIf
							$sSourceString = $sLineValue
							$iState = 1
						Else ; empty $sLineValue, so we are in the header
							$sSourceString = ""
							$iState = 3
						EndIf
					Case Else
						MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'msgid' encountered while in State %d in %s.po line number %d.", $iState, $sLanguageCode, $iLineNumber))
				EndSwitch
			Case "msgstr"
				Switch $iState
					Case 1
						If StringLeft($sLineValue, 1) <> '"' Then
							MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgstr does not start with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLanguageCode, $iLineNumber))
						EndIf
						If StringRight($sLineValue, 1) <> '"' Then
							MsgBox($MB_ICONERROR, $apptitle, StringFormat('Error in ParsePoFile: msgstr does not end with ". Continuing, but you must expect strange runtime issues. %s.po line number %d.', $sLanguageCode, $iLineNumber))
						EndIf
						$sTranslatedString = $sLineValue
						If ($sSourceString > '""') Then
							If ($sTranslatedString > '""') Then
								Local $iStringIndex = getStringIndex($sSourceString)
								$aTranslatedStrings[$iStringIndex][$iLanguageIndex] = $sTranslatedString ; <----- CORE CALL
							Else	; $sTranslatedString is empty
								$sMissingTranslations &= StringFormat("Line %4d: %s", $iLineNumber, $sSourceString) & @CRLF
							EndIf
						Else ; SourceString trivially short. nothing to do. This occurs regularly when processing the header
						EndIf
						; clean up collected attributes
						Local $sSourceString = ""
						Local $sTranslatedString = ""
						$iState = 0
					Case 3 ; after empty msgid
						$iState = 4
					Case Else
						MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'msgstr' encountered while in State %d in %s.po line number %d.", $iState, $sLanguageCode, $iLineNumber))
				EndSwitch
			Case "ignore"
				Switch $iState
					Case 0, 2, 4
						$iState = 0
					Case Else
						MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: LineType 'ignore' encountered while in State %d in line number %d.", $iState, $iLineNumber))
				EndSwitch
			Case Else ; irregular line type. This does occur very often in the header.
				Switch $iState
					Case 4
						; nothing to do; any "garbage" is o.k. here
					Case Else
						MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in ParsePoFile: illegal LineType %s in state %d in line number %d.", $sLineType, $iState, $iLineNumber))
				EndSwitch
		EndSwitch
	WEnd
	If StringLen($sMissingTranslations) > 0 Then
		MsgBox($MB_ICONERROR, $apptitle, StringFormat("Missing translations in %s.po:", $sLanguageCode) & @CRLF & $sMissingTranslations)
	EndIf
EndFunc   ;==>ParsePoFile
Func WriteOutputCode($hOutputAu3) ; write big nested Switch statement to the output file, pointed to by file handle $hOutputAu3
	; Return false and MsgBox if trouble
	; write header
	FileWriteLine($hOutputAu3, "; DO NOT EDIT. Generated by " & @ScriptName & " at " & @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & ":" & @MIN & ":" & @SEC)
	FileWriteLine($hOutputAu3, "#include-once")
	; write main function with large Switch groups
	FileWriteLine($hOutputAu3, "Func gettext_au3_runtime(Const $sSourceString, Const $sLanguageCode)")
	FileWriteLine($hOutputAu3, "    Switch $sSourceString")
	For $iStringIndex = 0 To UBound($aSourceStrings) - 1
		Local $sSourceString = $aSourceStrings[$iStringIndex]
		;MsgBox(262144, 'Debug line ~' & @ScriptLineNumber, 'Selection:' & @CRLF & '$sSourceString' & @CRLF & @CRLF & 'Return:' & @CRLF & $sSourceString) ;### Debug MSGBOX
		If StringLen($sSourceString) < 1 Then ContinueLoop ; skip empty source strings
		FileWriteLine($hOutputAu3, "        Case " & $sSourceString)
		FileWriteLine($hOutputAu3, "            Switch $sLanguageCode")
		For $iLanguageIndex = 0 To UBound($aLanguageCodes) - 1
			Local $sLanguageCode = $aLanguageCodes[$iLanguageIndex]
			;MsgBox(262144, 'Debug line ~' & @ScriptLineNumber, 'Selection:' & @CRLF & '$sLanguageCode' & @CRLF & @CRLF & 'Return:' & @CRLF & $sLanguageCode) ;### Debug MSGBOX
			If StringLen($sLanguageCode) < 1 Then ContinueLoop ; skip empty language codes
			Local $sTranslatedString = $aTranslatedStrings[$iStringIndex][$iLanguageIndex]
			If StringLen($sTranslatedString) < 1 Then ContinueLoop ; skip empty translations
			FileWriteLine($hOutputAu3, '                Case "' & $sLanguageCode & '"')
			FileWriteLine($hOutputAu3, '                    Return ' & $sTranslatedString)
		Next ; $iLanguageIndex
		FileWriteLine($hOutputAu3, "            EndSwitch ; $sLanguageCode")
	Next ; $iStringIndex
	FileWriteLine($hOutputAu3, "    EndSwitch ; $sSourceString")
	FileWriteLine($hOutputAu3, "    ; if execution gets here, no lang/text pair has matched.")
	FileWriteLine($hOutputAu3, "    Return '' ; '' signifying 'translation missing'")
	FileWriteLine($hOutputAu3, "EndFunc")
	; write small function with list of languages
	FileWriteLine($hOutputAu3, "Func gettext_au3_language_list()")
	For $iLanguageIndex = 0 To UBound($aTranslatedStrings, 2) - 1
		Local $sLanguageCode = $aLanguageCodes[$iLanguageIndex]
		If StringLen($sLanguageCode) < 1 Then ContinueLoop ; skip empty language codes
		; add language Names to Language List
		If StringLen($sLanguageList) > 1 Then $sLanguageList &= "|" ; separator between languages, but add it only if this would become the second or additional language. Avoids unneeded |s at the beginning or end
		$sLanguageList &= StringFormat("%s:%s", $sLanguageCode, gettext_au3_language_name($sLanguageCode))
	Next ; $iLanguageList
	FileWriteLine($hOutputAu3, StringFormat('    Return "%s"', $sLanguageList))
	FileWriteLine($hOutputAu3, "EndFunc")
EndFunc   ;==>WriteOutputCode
#Region Main Program
Global $apptitle = "msgfmt gettext generator"
WalkThroughPoFiles() ; <----- CORE INPUT CALL
FileDelete($sAu3OutputFileName) ; remove leftover from previous run
Local $hOutputAu3 = FileOpen($sAu3OutputFileName, $FO_OVERWRITE)
If $hOutputAu3 = -1 Then
	MsgBox($MB_ICONERROR, $apptitle, StringFormat("Error in gettext_au3_msgfmt Main program: Can't open output file %s .", $sAu3OutputFileName))
	Exit 2
EndIf
WriteOutputCode($hOutputAu3) ; <------ CORE OUTPUT CALL
FileClose($hOutputAu3)
Exit
#EndRegion Main Program
