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
#include <Array.au3>
#include <ComboConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include "..\StringSize\StringSize.au3"

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
	;Opt("GUIOnEventMode", 0) ; use message loop mode
	
	; sanitize language list
	If StringLeft($sLanguageList, 1) = "|" Then $sLanguageList = StringTrimRight($sLanguageList, 1)
	If StringRight($sLanguageList, 1) = "|" Then $sLanguageList = StringTrimLeft($sLanguageList, 1)
	
	; split language list into an array and get language count
	Local $aTemp = StringSplit($sLanguageList, "|")
	Local $iLanguageCount = UBound($aTemp) - 1
	
	; create separate arrays to hold language code and language definition
	Local $aLangCode[$iLanguageCount]
	Local $aLangDef[$iLanguageCount]
	Local $defaultChoice
	Local $iMaxWidthLanguageDef = 0
	For $i = 1 To $iLanguageCount
		Local $aLangInfo = StringSplit($aTemp[$i], ":")
		$aLangCode[$i-1] = $aLangInfo[1]
		If $aLangInfo[1] = $sDefaultLang Then
			$defaultChoice = $aLangInfo[2]
		EndIf
		$aLangDef[$i-1] = $aLangInfo[2]
		Local $aSize = _StringSize($aLangDef[$i-1])
		If $aSize[2] > $iMaxWidthLanguageDef then
			$iMaxWidthLanguageDef = $aSize[2]
		EndIf
	Next
	Local $sDisplayList = _ArrayToString ($aLangDef)

	Local $bDefaultLanguageFound = False
	Local $margin = 10
	Local $col1left = $margin
	
	Local $sLabel = gettext("Select your language:")
	Local $aSize = _StringSize($sLabel)
	Local $col1width = $aSize[2]
	Local $col2left = $col1left + $col1width + $margin
	
	Local $col2width = $iMaxWidthLanguageDef + $margin ; margin needed to prevent text overlap with scrollbar
	Local $col3left = $col2left + $col2width + $margin

	Local $sOK = gettext("OK")
	Local $aSize = _StringSize($sOK)
	Local $col3width = $aSize[2] + 20 ; additional 20 gives nice margin for button label 
	Local $rightEnd = $col3left + $col3width + $margin
	Local $lineheight = 25
	
	Local $windowSize
	Local $aSize = _StringSize($sApptitle)
	If $aSize[2] + 172 > $rightEnd Then
		$windowSize = $aSize[2] + 172
	Else
		$windowSize = $rightEnd
	EndIf
	Local $userdataWindow = GUICreate($sApptitle, $windowSize, $margin + $lineheight + $margin)
	
	Local $nextTop = $margin
	
	; create a label for combo box
	GUICtrlCreateLabel ($sLabel, $col1left, $nextTop + 4, $col1width, $lineheight) 
	
	; Add Dropdown List of Language Choices
	Local $hCombo = GUICtrlCreateCombo("", $col2left, $nextTop + 2, $col2width, $lineheight, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	GUICtrlSetData($hCombo, $sDisplayList, $defaultChoice)

	; Add OK Button
	Local $hOKbutton = GUICtrlCreateButton($sOK, $col3left, $nextTop, $col3width)
	
	GUISetState(@SW_SHOW, $userdataWindow)
	Local $langRes = $sDefaultLang ; default value if no button is checked
	While 1
		Local $idMsg = GUIGetMsg()
		Switch $idMsg
			Case $hOKbutton
				Local $selected = GUICtrlRead($hCombo)
				
				; derive $langRes from selected option
				Local $index = _ArraySearch($aLangDef, $selected)
				$langRes = $aLangCode[$index]
				ExitLoop
			Case $GUI_EVENT_CLOSE
				$langRes = "cancel"
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($userdataWindow)
	Return $langRes
EndFunc   ;==>gettext_au3_language_select_ui

Func GetUserDefaultLocaleName()
  Local $aRet = DllCall("kernel32.dll", "int", "GetUserDefaultLocaleName", "wstr", "", "int", 85)
  Return $aRet[1]
EndFunc ;==>GetUserDefaultLocaleName
