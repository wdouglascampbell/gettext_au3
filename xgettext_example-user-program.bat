xgettext -L C --from-code=UTF-8 --strict --no-wrap -o .\i18n\example-user-program\messages.pot example-user-program.au3
msgmerge --no-wrap -U .\i18n\example-user-program\en-us.po .\i18n\example-user-program\messages.pot
msgmerge --no-wrap -U .\i18n\example-user-program\de-de.po .\i18n\example-user-program\messages.pot
START /D .\i18n\example-user-program "C:\Program Files (x86)\AutoIt3\AutoIt3.exe" gettext_au3_msgfmt.au3
timeout /t 60
