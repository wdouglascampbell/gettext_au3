#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:		Martin Stut

	Script Function:
	Runtime Library to be included in AU3 programs intending to use gettext

	Requires some Global variables that need to be set by the calling application:
	Global $aLanguageList[4][3] = [["en", "English", "English"], ["es", "Spanish", "Español"], ["ko", "Korean", "한국어"], ["de", "German", "Deutsch"]]
	Global $apptitle = "Internationalized Test Application"
	Global $gettext_au3_lang = gettext_au3_language_select_ui()	; "en" or "de" or ...
	Sets
#ce ----------------------------------------------------------------------------
#include-once
#include <GUIConstantsEx.au3>
#include "gettext_au3_gettext.au3"
#forcedef $gettext_au3_lang
Global $gettext_au3_sourceString = ""	; source string of the last call to gettext. Useful if e.g. logging in English while msgboxing in userlang
Func gettext_au3_language_select_ui($apptitle, $sLanguageList, $defaultLang = "en") ; ask the user by GUI for his preferred language, return three letter code like ESET
	; Return $defaultLang in case of Cancel
	; parameters must look like
	; $sLanguageList = "en,English|es,Español|ko,한국어|de,Deutsch"
	; $apptitle = "Internationalized Test Application"
	Opt("GUIOnEventMode", 0) ; use message loop mode
	; sanitize and slice language list into array $aLanguageList
	If StringLeft($sLanguageList,1) = "|" Then $sLanguageList = StringTrimRight($sLanguageList,1)
	If StringRight($sLanguageList,1) = "|" Then $sLanguageList = StringTrimLeft($sLanguageList,1)
	Local $aLanguageList = StringSplit($sLanguageList, "|")
	Local $languageCount = $aLanguageList[0]
	Local $margin = 10
	Local $col1left = $margin
	Local $col1width = 40
	Local $col2left = $col1left + $col1width + $margin
	Local $col2width = 200
	Local $col3left = $col2left + $col2width + $margin
	Local $col3width = 70
	Local $rightEnd = $col3left + $col3width + $margin
	Local $lineheight = 20
	Local $userdataWindow = GUICreate($apptitle, $rightEnd, ($languageCount + 5) * $lineheight)
	Local $nextTop = $margin
	; create a Radio Button list with one button per language
	GUICtrlCreateGroup("Select your language:", $col1left, $nextTop + 2, $rightEnd - 2 * $margin, ($languageCount + 1) * $lineheight + 6)
	$nextTop += $lineheight
	Local $radioButton[$languageCount+1]
	For $i = 1 To $languageCount
		Local $aLangDef = StringSplit($aLanguageList[$i], ",")
		$radioButton[$i] = GUICtrlCreateRadio($aLangDef[2], $col1left + $margin, $nextTop, $rightEnd - 4 * $margin, $lineheight)
		If $aLangDef[1] = $defaultLang Then
			GUICtrlSetState(-1, $GUI_CHECKED)
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
	Local $langRes = $defaultLang ; default value if no button is checked
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
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($userdataWindow)
	Return $langRes
EndFunc   ;==>gettext_au3_language_select_ui
Func gettext(Const $sSourceText)	; return translated version of $sSourceText
	$gettext_au3_sourceString &= $sSourceText & @CRLF
	If StringLen($sSourceText) < 1 Then Return $sSourceText
	; when execution gets here, $sSourceText is guaranteed to be non-empty
	Local $sTranslatedText = gettext_au3_runtime($sSourceText, $gettext_au3_lang)
	If StringLen($sTranslatedText) < 1 Then Return '**' & $sSourceText ; incomplete translation
	Return $sTranslatedText
EndFunc   ;==>gettext
