#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Martin Stut

	Script Function:
	List of language codes
	Included by gettext_au3_msgfmt.au3, not by runtime
#ce ----------------------------------------------------------------------------
#include-once
Func gettext_au3_language_name($language_code) ; Return the name of the language of code par1, in the language
	; e.g. en -> English, de -> Deutsch
	Switch $language_code
		Case "ch"
			Return "繁體字"	; (traditional Chinese)"
		Case "de"
			Return "Deutsch"
		Case "en"
			Return "English"
		Case "es"
			Return "Español"
		Case "fr"
			Return "Français"
		Case "it"
			Return "Italiano"
		Case "ko"
			Return "한국어"
		Case "nl"
			Return "Nederlands"
		Case "no"
			Return "Norsk"
		Case "pt"
			Return "Português"
		Case "ro"
			Return "Românâ"
		Case Else
			Return $language_code & "-language"
	EndSwitch
EndFunc   ;==>gettext_au3_language_name
