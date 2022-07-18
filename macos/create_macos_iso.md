# create_macos_iso

## macOS Big Sur

```bash
# list all connection
hdiutil create -o /tmp/Big_Sur.cdr -size 13312m -layout SPUD -fs HFS+J

hdiutil attach /tmp/Big_Sur.cdr.dmg -noverify -mountpoint /Volumes/install_build

hdiutil detach /Volumes/Install\ macOS\ Big\ Sur/

hdiutil convert /tmp/Big_Sur.cdr.dmg -format UDTO -o ~/Downloads/Big_Sur.iso

mv /tmp/Big_Sur.cdr.dmg ~/Downloads/Big_Sur.dmg
#
mv ~/Downloads/Big_Sur.iso.cdr ~/Downloads/Big_Sur.iso
```


---

## macOS Catalina

```bash
hdiutil create -o /tmp/Catalina.cdr -size 8500m -layout SPUD -fs HFS+J

hdiutil attach /tmp/Catalina.cdr.dmg -noverify -mountpoint /Volumes/install_build

sudo /Applications/Install\ macOS\ Catalina.app/Contents/Resources/createinstallmedia --volume /Volumes/install_build

hdiutil detach /Volumes/Install\ macOS\ Catalina

hdiutil convert /tmp/Catalina.cdr.dmg -format UDTO -o ~/Desktop/Catalina.iso

mv ~/Desktop/Catalina.iso.cdr ~/Desktop/Catalina.iso

mv /tmp/Catalina.cdr.dmg ~/Desktop/Catalina.dmg
```


---

## macOS Mojave

```bash
hdiutil create -o /tmp/Mojave.cdr -size 6000m -layout SPUD -fs HFS+J

hdiutil attach /tmp/Mojave.cdr.dmg -noverify -mountpoint /Volumes/install_build

sudo /Applications/Install\ macOS\ Mojave.app/Contents/Resources/volume /Volumes/install_buildcreateinstallmedia

sudo /Applications/Install\ macOS\ Mojave.app/Contents/Resources/createinstallmedia --volume /Volumes/install_build

hdiutil detach /Volumes/Install\ macOS\ Mojave

hdiutil convert /tmp/Mojave.cdr.dmg -format UDTO -o ~/Desktop/Mojave.iso

mv ~/Desktop/Mojave.iso.cdr ~/Desktop/Mojave.iso

mv /tmp/Mojave.cdr.dmg ~/Desktop/Mojave.dmg
```

---

## create macOS ISO & dmg via script 
```bash
# 1. Download the image from [How to get old versions of macOS](https://support.apple.com/en-gb/HT211683)
# 2. copy this shell file somewhere in your Mac
# 3. chmod +x create_macos_mojave_10.14_iso_and_dmg.sh
# 4. $ sudo ./create_macos_mojave_10.14_iso_and_dmg.sh
# The ISO & dmg file will be located in your Desktop when the script will be complete
```
## ref

[How to get old versions of macOS](https://support.apple.com/en-gb/HT211683)
