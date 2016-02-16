#!/bin/bash

# Part of rawbotz, (c) Felix Wolfsteller 2016
# Licensed under the GPLv3

set -e

command -v dialog >/dev/null 2>&1 || { 
  echo >&2 "The program 'dialog' seems not to be installed, exiting."
  exit 1
}

PROGRESS_WIDTH=60
PROGRESS_HEIGHT=30

RAWBOTZ_CONF="rawbotz.conf"

menu_selection=$(mktemp /tmp/rawbotz_maintenance.XXXXXX)

dialog --menu "Rawbotz Menu" 18 30 8 \
  1 "Start rawbotz on port 9711" \
  2 "Update local magento products" \
  3 "Look for new remote products" \
  4 "Save current stock data" \
  2> tmp

if [ "$?" = 0 ]
then
  _ret=$(cat tmp)
  rm tmp
  if [ "$_ret" = "1" ]
  then
    echo "starting rawbotz"
    ./start_rb.sh
  fi
  if [ "$_ret" = "2" ]
  then
    bundle exec rawbotz_update_local_products -v -c "$RAWBOTZ_CONF" | sed -e 's/.* -- : //' | dialog --progressbox "Update local magento products" $PROGRESS_HEIGHT $PROGRESS_WIDTH
  fi
  if [ "$_ret" = "3" ]
  then
    rawbotz_update_remote_products -c "$RAWBOTZ_CONF" | sed -e 's/.* -- : //' | dialog --progressbox "Updating Remote Products" $PROGRESS_HEIGHT $PROGRESS_WIDTH
  fi
  if [ "$_ret" = "4" ]
  then
    rawbotz_stock_update -v -c "$RAWBOTZ_CONF" | dialog --progressbox "Saving current stock data" $PROGRESS_HEIGHT $PROGRESS_WIDTH
  else
    echo "Bad choice."
    exit 1
  fi
fi

rm "$menu_selection"

exit 0
