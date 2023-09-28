#cs ----------------------------------------------------------------------------

AutoIt Version: 3.3.14.2
Author:         Martin Stut

Script Function:
	Example of an end user program that is available in several languages

#ce ----------------------------------------------------------------------------
AutoItSetOption("MustDeclareVars", 1)
#include "i18n\example-user-program\gettext_au3_gettext.au3"
#include "gettext_au3_runtime_library.au3"
Local $apptitle = "Internationalized Test Application"
Global $gettext_au3_lang = gettext_au3_language_select_ui($apptitle, gettext_au3_language_list(), GetUserDefaultLocaleName())
Local $apptitle = gettext("Internationalized Test Application")
Local $apptitle_en = $gettext_au3_sourceString
MsgBox(64, $apptitle, StringFormat(gettext("gettext_au3_language_select_ui() has returned %s%s%s."), '"', $gettext_au3_lang, '"'))
If $gettext_au3_lang = "cancel" Then
	Exit
EndIf
Local $sBook = gettext("Gospel of John")
Local $nChapter = 3
Local $nVerse = 16
$gettext_au3_sourceString = ""
MsgBox(64, $apptitle, StringFormat(gettext("Jesus loves you!") & @CRLF & gettext("See the Bible, %s, chapter %d, verse %d."), $sBook, $nChapter, $nVerse))
MsgBox(64, $apptitle_en, StringFormat($gettext_au3_sourceString, $sBook, $nChapter, $nVerse))
MsgBox(64, $apptitle, gettext("Good bye!"))
Exit
