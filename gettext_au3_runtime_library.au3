#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:		Martin Stut

	Script Function:
	Runtime Library to be included in AU3 programs intending to use gettext

	Requires some Global variables that need to be set by the calling application:
	Global $sApptitle = "Internationalized Test Application"
	Global $gettext_au3_lang = gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", gettext_au3_windows2char(@OSLang))
	Sets
#ce ----------------------------------------------------------------------------
#include-once
#include <GUIConstantsEx.au3>
#include "gettext_au3_gettext.au3"
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
Func gettext_au3_windows2char($sLanguageCodeWindows) ; Return the two character code (e.g. "en") from the String representation of the hexadecimal Windows Locale Identifier (e.g. "0409") as returned by @OSLang
	; example use: $slanguageCode = gettext_au3_windows2char(@OSLang)
	; returns "00" if not found
	; compiled from https://msdn.microsoft.com/en-us/library/windows/desktop/dd318693%28v=vs.85%29.aspx
	; Intended use: $sUserLang =  gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", gettext_au3_windows2char(@OSLang))
	Local $sPrimaryLanguageCodeWindows = StringLower(StringRight($sLanguageCodeWindows, 2))
	Switch $sPrimaryLanguageCodeWindows
		Case "01"
			Return "ar"
		Case "02"
			Return "bg"
		Case "03"
			Return "ca"
		Case "04"
			Return "zh"
		Case "05"
			Return "cs"
		Case "06"
			Return "da"
		Case "07"
			Return "de"
		Case "08"
			Return "el"
		Case "09"
			Return "en"
		Case "0a"
			Return "es"
		Case "0b"
			Return "fi"
		Case "0c"
			Return "fr"
		Case "0d"
			Return "he"
		Case "0e"
			Return "hu"
		Case "0f"
			Return "is"
		Case "10"
			Return "it"
		Case "11"
			Return "ja"
		Case "12"
			Return "ko"
		Case "13"
			Return "nl"
		Case "14"
			Return "no"
		Case "15"
			Return "pl"
		Case "16"
			Return "pt"
		Case "17"
			Return "rm"
		Case "18"
			Return "ro"
		Case "19"
			Return "ru"
		Case "1a"
			Return "sr"
		Case "1b"
			Return "sk"
		Case "1c"
			Return "sq"
		Case "1d"
			Return "sv"
		Case "1e"
			Return "th"
		Case "1f"
			Return "tr"
		Case "20"
			Return "ur"
		Case "21"
			Return "id"
		Case "22"
			Return "uk"
		Case "23"
			Return "be"
		Case "24"
			Return "sl"
		Case "25"
			Return "et"
		Case "26"
			Return "lv"
		Case "27"
			Return "lt"
		Case "28"
			Return "tg"
		Case "29"
			Return "fa"
		Case "2a"
			Return "vi"
		Case "2b"
			Return "hy"
		Case "2c"
			Return "az"
		Case "2f"
			Return "mk"
		Case "32"
			Return "tn"
		Case "34"
			Return "xa"
		Case "35"
			Return "zu"
		Case "36"
			Return "af"
		Case "37"
			Return "ka"
		Case "38"
			Return "fo"
		Case "39"
			Return "hi"
		Case "3a"
			Return "mt"
		Case "3b"
			Return "se"
		Case "3c"
			Return "ga"
		Case "3e"
			Return "ms"
		Case "3f"
			Return "kk"
		Case "40"
			Return "ky"
		Case "41"
			Return "sw"
		Case "42"
			Return "tk"
		Case "43"
			Return "uz"
		Case "44"
			Return "tt"
		Case "45"
			Return "bn"
		Case "46"
			Return "pa"
		Case "47"
			Return "gu"
		Case "48"
			Return "or"
		Case "49"
			Return "ta"
		Case "4a"
			Return "te"
		Case "4b"
			Return "kn"
		Case "4c"
			Return "ml"
		Case "4d"
			Return "as"
		Case "4e"
			Return "mr"
		Case "4f"
			Return "sa"
		Case "50"
			Return "mn"
		Case "51"
			Return "bo"
		Case "52"
			Return "cy"
		Case "53"
			Return "kh"
		Case "54"
			Return "lo"
		Case "56"
			Return "gl"
		Case "59"
			Return "sd"
		Case "5b"
			Return "si"
		Case "5d"
			Return "iu"
		Case "5e"
			Return "am"
		Case "61"
			Return "ne"
		Case "62"
			Return "fy"
		Case "63"
			Return "ps"
		Case "65"
			Return "dv"
		Case "67"
			Return "ff"
		Case "68"
			Return "ha"
		Case "6a"
			Return "yo"
		Case "6d"
			Return "ba"
		Case "6e"
			Return "lb"
		Case "6f"
			Return "kl"
		Case "70"
			Return "ig"
		Case "73"
			Return "ti"
		Case "78"
			Return "ii"
		Case "7e"
			Return "br"
		Case "80"
			Return "ug"
		Case "81"
			Return "mi"
		Case "82"
			Return "oc"
		Case "83"
			Return "co"
		Case "87"
			Return "rw"
		Case "88"
			Return "wo"
		Case "92"
			Return "ku"
		Case Else
			Return "00"
	EndSwitch
	; Default in case the Switch did not return anything
	Return "00"
EndFunc   ;==>gettext_au3_windows2char
Func gettext_au3_language_select_ui($sApptitle, $sLanguageList, $sDefaultLang = "en") ; ask the user by GUI for his preferred language, return two letter code
	; Return "cancel" in case of Cancel - modification 2016-09-09 by MST to enable calling environment to detect "cancel" case
	; parameters must look like
	; $sLanguageList = "en,English|es,Español|ko,한국어|de,Deutsch"
	; $sApptitle = "Internationalized Test Application"
	; Intended use: $sUserLang =  gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", gettext_au3_windows2char(@OSLang))
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
		Local $aLangDef = StringSplit($aLanguageList[$i], ",")
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
				Local $aLangDef = StringSplit($aLanguageList[$i], ",")
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
;$sUserLang = gettext_au3_language_select_ui("Test App", "en,English|es,Español|de,Deutsch|ko,한국어", gettext_au3_windows2char(@OSLang))
;MsgBox(262144, 'Debug line ~' & @ScriptLineNumber, 'Selection:' & @CRLF & '$sUserLang' & @CRLF & @CRLF & 'Return:' & @CRLF & $sUserLang) ;### Debug MSGBOX
