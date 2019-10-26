
#!/bin/bash

#Praktisches Skript für alle mydealerz. Am besten diese Codezeilen mit crontab -e jede Minute ausführen lassen (siehe: https://www.linuxwiki.de/crontab)
#Die folgenden Zeilen prüfen dann jede Minute (oder von mir aus Sekunde) ob es einen neuen Preisfehler-Deal gibt und schickt dann eine Telegram-Nachricht mit dem Link raus
#So ist es nun möglich tatsächlich auch _rechtzeitig_ über Preisfehler informiert zu werden und nicht erst ~10 Minuten später (beim ersten ausführen wird eine Preisfehler-Nachricht verschickt da eine Referenz fehlt, ist aber völlig normal)

mydealz_search="preisfehler"
message_text="Preisfehler!"

telegram_token=""
telegram_chat_id=""


## Start Script

path=$(readlink -f $0 | xargs dirname)
touch $path/.tmp_file_lastknowndeals
last_deals=$(paste -sd'|' $path/.tmp_file_lastknowndeals)
sleep 1
#wellp, thats a long pipe
new_deals=$(wget --header "Cookie: sort_by=%22new%22" --timeout=5 --tries=1 -qO- https://www.mydealz.de/search?q=$mydealz_search -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*" | awk '!seen[$0]++' | grep '/deals/' | tail -n +2)
if [ -n "$new_deals" ]; then
  echo $new_deals | tr " " "\n" > $path/.tmp_file_lastknowndeals
else
  exit 0
fi
if [ -z $last_deals ]; then
  last_deals=$(paste -sd'|' $path/.tmp_file_lastknowndeals | cut -d"|" -f 2-)
fi
sleep 1
for new_deal in $new_deals; do
  if [[ ! $new_deal =~ $(echo ^\($last_deals\)$) ]]; then
    #new deal! telegram action in 3...2...1...
    #https://core.telegram.org/bots/api
    URL="https://api.telegram.org/bot$telegram_token/sendMessage"
    curl -s -X POST $URL -d chat_id=$telegram_chat_id -d text="$message_text $new_deal"
  else
    break
  fi
done
