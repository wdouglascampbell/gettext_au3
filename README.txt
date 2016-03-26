# gettext_au3 - Internationalization of AU3 Applications by Something Similar to GNU Gettext

For a general overview of the GNU gettext system see https://en.wikipedia.org/wiki/Gettext
It really helps to know what the creators of gettext have meant things to be like.

You can find detailed information in  https://www.gnu.org/software/gettext/manual/index.html

## Install related tools

Current (as of 2016-03) Windows binaries of the general GNU gettext utilities can be obtained from
https://mlocati.github.io/gettext-iconv-windows/
Running the downloaded exe installs the binaries in a subdirectory of C:\Program Files with the option of adding that subdirectory to your %PATH% environment variable.


## Prepare Source Code

### Enclose all strings that need translation in gettext("english version of translatable string").

The argument of gettext must always be one (1) single, uninterrupted literal string.

This rule imples:
* Never ever use line continuation inside the argument of gettext. Use variables and separate gettext lines instead.
* Never ever use variables inside the argument of gettext. If you need variables,
use e.g.
StringFormat(gettext("My name is %s and I live in %s."), $sName, $sCity)
* Never ever use String concatenation inside the argument of gettext.
If you are composing long messages, do it like this:
MsgBox(..., ..., gettext("Translatable Part 1") & @CRLF & gettext("Translatable Part 2"))

### Include the Runtime Library

'''
#include "gettext_au3_runtime_library.au3"
'''

### Declare and Populate the Required Variables, one of them Global

'''
Local $aLanguageList[2][3] = [["en", "English", "English"], ["de", "German", "Deutsch"]]
Local $apptitle = "Internationalized Test Application"
Global $gettext_au3_lang = gettext_au3_language_select_ui($apptitle, $aLanguageList, "en")
'''

## Generate the Template File (.pot)


The programmer needs to repeat this step after each modification to the source code that might have changed translatable strings, so he'll want to include this step into your makefile, generate.au3 or whatever build system you use.

The template file is one single file, common to all user languages, containing all the strings that need to be translated

'''
xgettext -L C --from-code=UTF-8 --strict --omit-header --no-wrap -o messages.pot example-user-program.au3
'''

Add source code files as needed. You need to specify every single .au3 file.

### Copy Template file to Language-Specific PO file 

This needs to be done only once per language, usually after the first generation of messages.pot .

E.g. for language de:
'''
copy messages.pot de.po
'''
Very important: edit the Content-Type Header in the language-specific .po file to read UTF-8 instead of CHARSET.

### Merge Updated Messages and Existing Translations

This needs to be done whenever a modified messages.pot was created.

'''
msgmerge --no-wrap -U de.po messages.pot
'''


## Create the Translations

For each language send the .po file to the translator, asking her to fill the msgstr lines.

There are tools available that make this process easier.

Segments that have been changes since the last translation are marked with "fuzzy" by msgmerge.

## Generate the au3 source table

After the translations are back from the translators, run msgfmt.au3 (or its compiled version msgfmt.exe), generating gettext_au3_gettext.au3 from all **.po files in the current directory.
The output file name is hard coded in msgfmt.au3 to ensure consistency with gettext_au3_runtime_library.au3, which includes this file.

## Compile a New Version of Your Application With Updated Translations

