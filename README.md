# Universal deep_buffer Remover
This hack fixes when streaming apps (Spotify, Pandora, etc) do not process audio effects for various equalizer applications. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

### Dependencies
* [Audio Modification Library](https://forum.xda-developers.com/apps/magisk/module-audio-modification-library-t3579612) @ XDA Developers

## Compatibility
* Android Jellybean+
* Magisk install (MagiskSU/SuperSU)
* Pixel support
* System install
* Works with nearly every device, kernel, and rom

## Change Log
v2.4
	- AudModLib v1.4 update which changes SELinux live patching to allow better compatibility between different devices, kernels, and roms; while also keeping the amount of "allowances" to a minumum
	- AudModLib v1.4: changed post-fs-data(.d)/service(.d) shell script names for cosmetic recognition
	- AudModLib v1.4: merge SuperSU shell script with MagiskSU post-fs-data(.d) script for less fragmentation
	- AudModLib v1.4: added /cache/audmodlib.log to determine if script has run successfully
	- Install script changes that include: major update to Pixel (A/B OTA) support, mounting changes, improved script efficiency, fixes & consolidation
	- Add more deep_buffer remover compatibility between differing devices and ROMs

v2.3
	- AudModLib v1.3 update push which includes the script addition to allow various audio mods working with SELinux Enforcing
	- Remove (audmodlib)service.sh and replace with post-fs-data(.d) audmodlib.sh, which should fix when root may be lost upon installing certain mods

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