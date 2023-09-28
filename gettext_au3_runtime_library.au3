#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:		Martin Stut

	Script Function:
	Runtime Library to be included in AU3 programs intending to use gettext

	Requires some Global variables that need to be set by the calling application:
	Global $sApptitle = "Internationalized Test Application"
	Global $gettext_au3_lang = gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", GetUserDefaultLocaleName())
	Sets
#ce ----------------------------------------------------------------------------
#include-once
#include <GUIConstantsEx.au3>
;#include "gettext_au3_gettext.au3"
#forcedef $gettext_au3_lang
Global $gettext_au3_sourceString = "" ; source string of the last call to gettext. Useful if e.g. logging in English while msgboxing in userlang
Func gettext(Const $sSourceText) ; return translated version of $sSourceText; MAIN CORE FUNCTION
	$gettext_au3_sourceString &= $sSourceText & @CRLF
	If StringLen($sSourceText) < 1 Then Return $sSourceText
	; when execution gets here, $sSourceText is guaranteed to be non-empty
	Local $sTranslatedText = gettext_au3_runtime($sSourceText, $gettext_au3_lang)
	If StringLen($sTranslatedText) < 1 Then Return '*' & $sSourceText ; incomplete translation
	Return $sTranslatedText
EndFunc   ;==>gettext
Func gettext_au3_language_select_ui($sApptitle, $sLanguageList, $sDefaultLang = "en-us") ; ask the user by GUI for his preferred language
	; Return "cancel" in case of Cancel - modification 2016-09-09 by MST to enable calling environment to detect "cancel" case
	; parameters must look like
	; $sLanguageList = "en-us,English|es-es,Español|ko-kr,한국어|de-de,Deutsch"
	; $sApptitle = "Internationalized Test Application"
	; Intended use: $sUserLang =  gettext_au3_language_select_ui("Test App", "en-us,English|es-es,Español|ko-kr,한국어|de-de,Deutsch", GetUserDefaultLocaleName())
	; if $sDefaultLang is not found within $sLanguageList, then the last element of $sLanguageList is pre-selected
	Opt("GUIOnEventMode", 0) ; use message loop mode
	; sanitize and slice language list into array $aLanguageList
	If StringLeft($sLanguageList, 1) = "|" Then $sLanguageList = StringTrimRight($sLanguageList, 1)
	If StringRight($sLanguageList, 1) = "|" Then $sLanguageList = StringTrimLeft($sLanguageList, 1)
	Local $aLanguageList = StringSplit($sLanguageList, "|")
	Local $languageCount = $aLanguageList[0]
	Local $bDefaultLanguageFound = False
	Local $margin = 10
	Local $col1left = $margin
	Local $col1width = 40
	Local $col2left = $col1left + $col1width + $margin
	Local $col2width = 200
	Local $col3left = $col2left + $col2width + $margin
	Local $col3width = 70
	Local $rightEnd = $col3left + $col3width + $margin
	Local $lineheight = 20
	Local $userdataWindow = GUICreate($sApptitle, $rightEnd, ($languageCount + 5) * $lineheight)
	Local $nextTop = $margin
	; create a Radio Button list with one button per language
	GUICtrlCreateGroup("Select your language:", $col1left, $nextTop + 2, $rightEnd - 2 * $margin, ($languageCount + 1) * $lineheight + 6)
	$nextTop += $lineheight
	Local $radioButton[$languageCount + 1]
	For $i = 1 To $languageCount
		Local $aLangDef = StringSplit($aLanguageList[$i], ":")
		$radioButton[$i] = GUICtrlCreateRadio($aLangDef[2], $col1left + $margin, $nextTop, $rightEnd - 4 * $margin, $lineheight)
		If ($aLangDef[1] = $sDefaultLang) Or (Not ($bDefaultLanguageFound) And ($i = $languageCount)) Then ; always select one language; if nothing matches, use the last one
			GUICtrlSetState(-1, $GUI_CHECKED)
			$bDefaultLanguageFound = True
		Else
			GUICtrlSetState(-1, $GUI_UNCHECKED)
		EndIf
		$nextTop += $lineheight
	Next
	GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
	$nextTop += $lineheight
	Local $iCANCELbutton = GUICtrlCreateButton("Cancel", $col1left, $nextTop, 70)
	Local $iOKbutton = GUICtrlCreateButton("OK", $col3left, $nextTop, 70)
	GUISetState(@SW_SHOW, $userdataWindow)
	Local $langRes = $sDefaultLang ; default value if no button is checked
	While 1
		For $i = 1 To $languageCount
			Local $buttonRes = GUICtrlRead($radioButton[$i])
			If $buttonRes = $GUI_CHECKED Then
				Local $aLangDef = StringSplit($aLanguageList[$i], ":")
				$langRes = $aLangDef[1]
				ExitLoop
			EndIf
		Next
		Local $idMsg = GUIGetMsg()
		Switch $idMsg
			Case $iOKbutton
				ExitLoop
			Case $GUI_EVENT_CLOSE, $iCANCELbutton
				$langRes = "cancel"
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($userdataWindow)
	Return $langRes
EndFunc   ;==>gettext_au3_language_select_ui
; disable for production
;$sUserLang = gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", GetUserDefaultLocaleName())
;MsgBox(262144, 'Debug line ~' & @ScriptLineNumber, 'Selection:' & @CRLF & '$sUserLang' & @CRLF & @CRLF & 'Return:' & @CRLF & $sUserLang) ;### Debug MSGBOX

Func GetUserDefaultLocaleName()
  Local $aRet = DllCall("kernel32.dll", "int", "GetUserDefaultLocaleName", "wstr", "", "int", 85)
  Return $aRet[1]
EndFunc ;==>GetUserDefaultLocaleName
