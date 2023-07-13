#!/bin/bash

DIALOG=${DIALOG=dialog}

$DIALOG --title "My Dialog Box" --clear \
        --yesno "Hello, this is my dialog box. Do you like it?" 10 30

case $? in
  0)
    echo "You said yes.";;
  1)
    echo "You said no.";;
  255)
    echo "You pressed ESC.";;
esac
