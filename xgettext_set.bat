xgettext -L C --from-code=UTF-8 --strict --no-wrap -o messages.pot example-user-program.au3
msgmerge --no-wrap -U en.po messages.pot
msgmerge --no-wrap -U de.po messages.pot
gettext_au3_msgfmt.exe
timeout /t 60
