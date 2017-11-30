# Universal deep_buffer Remover
This hack fixes when streaming apps (Spotify, Pandora, etc) do not process audio effects for various equalizer applications. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

### Dependencies
* [Audio Modification Library](https://forum.xda-developers.com/apps/magisk/module-audio-modification-library-t3579612) @ XDA Developers

## Compatibility
* Android Jellybean+
* init.d (other root & rootless) - requires init.d support. If you don't have init.d support, try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105)
* MagiskSU & SuperSU
* Magisk & System install
* Nexus/Pixel support (A/B OTA)
* SELinux enforcing
* Works with nearly every device, kernel, and rom

## Change Log
### v3.4 - 11.30.2017
* Updated to Unity/AML v2.4

### v3.3 - 11.28.2017
* Updated to Unity/AML v2.3

### v3.2 - 11.08.2017
* Updated to Unity/AML v2.2 - Please clean install Audio Modification Library and all modules (this will be the last version you'll have to clean install so in the future the auto clean install/upgrade script will take effect)

### v3.1 - 10.26.2017
* Unity/AML v2.1: Updated for Magisk v14.3
* Unity/AML v2.1: Updated to Magisk module template 1410
* Unity/AML v2.1: Massive script reduction & efficiency enhancements
* Unity/AML v2.1: Added XMLStartlet for arm/arm64 & x86 by JamesDSP developer, james3460297 @ XDA Developers (this toolkit allows the editing & patching of XML files using a simple set of shell commands in a way similar to how it is done with grep, sed, awk, diff, patch, join, etc commands)
* Unity/AML v2.1: Combined customrules.sh CP_PRFX command with MK_PRFX so by default, the command CP_PRFX both creates the directory and copies the file (thus removing the need to have two seperate customrules.sh for cp and mk)
* Unity/AML v2.1: Combined customrules.sh CP_PRFX command with CP_SFFX, so the default file placement permission is 0644 and the default folder creation permission is 0755 (you can manually define file copy permission by adding " 0755" or whatever permission you want at the end of the line that contains CP_PRFX)
* Unity/AML v2.1: Silently uninstall previous version before new version upgrades (this is to keep every upgrade install clean in cases where the new version doesn't include files the previous version may have included)
* Unity/AML v2.1: Further A/B OTA (Pixel family) improvements
* Unity/AML v2.1: System backup/restore fully automated (no need to manually write files to INFO file anymore)
* Unity/AML v2.1: Added MAXAPI variable to unity-uservariables that compliments MINAPI (this allows the developer to quickly set the minimum and maximum SDK version of their modification)
* Unity/AML v2.1: Added cabability for modifications to modify /data partition, with full backup/removal support
* Unity/AML v2.1: Greatly improved uninstall function by concatenating script
* Unity/AML v2.1: Added "minVer" (an internal check that should always be equal to the latest stable Magisk release in cases where the template is based off of a beta release)
* Unity/AML v2.1: Added support for SuperSU BINDSBIN mode
* Unity/AML v2.1: Fix cache system installs
* Unity/AML v2.1: Moved scripts to post-fs-data for Magisk installs (fixes some issues such as AM3D white screen on compatible devices)
* Unity/AML v2.1: Combined multiple wipe functions into one
* Unity/AML v2.1: Fixed System override issues some were facing
* Unity/AML v2.1: Fixed System install partition re-mounting
* Unity/AML v2.1: Updated Instructions (for developers only)
* Unity/AML v2.1: Addon.d script fixes/improvements
* Unity/AML v2.1: Various miscellaneous script fixes and improvements
	
### v3.0 - 09.25.2017
* Reworked the way deep_buffer removals function when a user uninstalls
* Unity/AML v2.0: Massive installer and script overhaul
* Unity v2.0: Added autouninstall (if mod is already installed and you flash same version zip again, it'll uninstall), thus removing the need for an uninstall zip
* Unity v2.0: Added file/folder backup/restore of modified files
* Unity v2.0: Added file/folder backup/restore of normally wiped files
* Unity v2.0: Added Osm0sis @ xda-developers uninstaller idea (just add "uninstall" to zip name and it'll function as uninstaller)
* Unity/AML v2.0: Added phh's SuperUser and LOS su support (note, LOS doesn't support sepolicy patching)
* Unity/AML v2.0: Added proxy library to AML to allow the proxy effects found in multiple audio modules
* Unity/AML v2.0: Added support for Magisk imgs located in /cache/audmodlib
* Unity v2.0: Added system_root support for Pixel devices
* Unity v2.0: Added system override (if you're on magisk but would rather have it install to system, add word "system" to zip name and it'll install everything but scripts to system)
* Unity v2.0: Add Unity system props
* Unity v2.0: Added vendor fix for Nexus devices
* Unty/AML v2.0: AML functionality and uses overhauled
* Unity/AML v2.0: Bug fixes
* Unity/AML v2.0: Modified Unity Installer to allow use for non AML modules
* Unity/AML v2.0: Moved scripts from Magisk .core to the individual module folder due to .core limitations
* Unity/AML v2.0: New modular approach - no need to modify update-binary anymore: check instructions for more details on how this works
* Unity v2.0: Reworked addon.d system install scripts
* Unity/AML v2.0: Removed AML cache workaround by reworking AML changes via magisk_merge
* Unity/AML v2.0: Reworked AML vendor audio_effects to not be overwritten by system audio_effects by commenting out conflicting lines
* Unity v2.0: Reworked script permissions
* Unity/AML v2.0: Update sepolicy for Magisk 13+
* Unity/AML v2.0: Updated to Magisk module template 1400

## Source Code
* Module [GitHub](https://github.com/therealahrion/Universal-deep_buffer-Remover)
