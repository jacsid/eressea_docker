#!/bin/bash

# this script is based on run-eressea.cron
# differences to original
#   it is possible to run a turn with empty orders 

eval "$(luarocks path)"
GAME=$1
ENABLE_EMPTY_ORDERS=$2
(
[ "$ENABLED" == "no" ] && exit
[ -z "$ERESSEA" ] && ERESSEA="$HOME/eressea"

export ERESSEA
BIN="$ERESSEA/server/bin"
TURN=$(cat "$ERESSEA/game-$GAME/turn")
if [ ! -e "$ERESSEA/game-$GAME/data/$TURN.dat" ]; then
  echo "data file $TURN is missing, cannot run turn for game $GAME"
  exit 1
fi
REPORTS="$ERESSEA/game-$GAME/reports"
if [ -d "$REPORTS" ]; then
  rm -rf "$REPORTS"
fi
mkdir "$REPORTS"

cd "$ERESSEA/game-$GAME" || exit

if [ -d test ]; then
  touch test/execute.lock
fi

"$BIN/create-orders" "$GAME" "$TURN"
if [ ! -s "$ERESSEA/game-$GAME/orders.$TURN" ]; then
    if [ "$ENABLE_EMPTY_ORDERS" != "yes" ]; then
      echo "server did not create orders for turn $TURN in game $GAME"
      exit 2
    fi
fi

"$BIN/backup-eressea" "$GAME" "$TURN"
rm -f execute.lock
"$BIN/run-turn" "$GAME" "$TURN"
touch execute.lock

if [ ! -s "$REPORTS/reports.txt" ]; then
  echo "server did not create reports.txt in game $GAME"
  exit 4
fi
"$BIN/backup-eressea" "$GAME" "$TURN"
let TURN=$TURN+1
if [ ! -s "$ERESSEA/game-$GAME/data/$TURN.dat" ]; then
  echo "server did not create data for turn $TURN in game $GAME"
  exit 3
fi
echo "sending reports for game $GAME, turn $TURN"
"$BIN/compress.sh" "$GAME" "$TURN"
"$BIN/sendreports.sh" "$GAME"
"$BIN/backup-eressea" "$GAME" "$TURN"
rm -f test/execute.lock
) | tee -a "$HOME/log/eressea.cron.log"

