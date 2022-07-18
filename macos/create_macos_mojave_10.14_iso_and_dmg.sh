#!/bin/bash
hdiutil create -o /tmp/Mojave.cdr -size 6000m -layout SPUD -fs HFS+J
hdiutil attach /tmp/Mojave.cdr.dmg -noverify -mountpoint /Volumes/install_build
sudo /Applications/Install\ macOS\ Mojave.app/Contents/Resources/createinstallmedia --volume /Volumes/install_build
hdiutil detach /Volumes/Install\ macOS\ Mojave
hdiutil convert /tmp/Mojave.cdr.dmg -format UDTO -o ~/Desktop/Mojave.iso
mv ~/Desktop/Mojave.iso.cdr ~/Desktop/Mojave.iso
mv /tmp/Mojave.cdr.dmg ~/Desktop/Mojave.dmg
