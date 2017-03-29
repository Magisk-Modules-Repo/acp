# Universal deep_buffer Remover
This hack fixes when streaming apps (Spotify, Pandora, etc) do not process audio effects for various equalizer applications. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

### Dependencies
* [Audio Modification Library](https://forum.xda-developers.com/apps/magisk/module-audio-modification-library-t3579612) by ahrion @ XDA Developers

## Compatibility
* Android Jellybean+
* Magisk install (MagiskSU/SuperSU)
* Pixel support
* System install
* Works with nearly every device, kernel, and rom

## Change Log
v2.3
	- AudModLib v1.3 update push which includes the script addition to allow various audio mods working with SELinux Enforcing
	- Remove (audmodlib)service.sh and replace with pos-fs-data(.d) audmodlib.sh, which should fix when root may be lost upon installing certain mods
	- System install will now have the same script updates as the AudModLib v1.3 to allow to work in SELinux Enforcing

v2.2
	- Added audmodlib.sh post-fs-data.d script
	- Install script fixes
	- post-fs-data.d script fixes
    - Push AudModLib v1.2 hotfixes
	
v2.1
    - AudModLib v1.1 hotfix for bootloops issues on some devices
	
v2.0
    - Initial Magisk release

## Source Code
* Module [GitHub](https://github.com/therealahrion/Universal-deep_buffer-Remover)