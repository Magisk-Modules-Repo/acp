# Audio Compatibility Patch
This fixes music and streaming apps (Spotify, Pandora, etc) that aren't processing audio effects for various equalizer applications through the modification of audio policy. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

## Compatibility
* Any Android device

## Change Log
### v1.5.2 - 12.28.2018
* Unity v2.0 update
* Fixed limitation in zipname triggers - you can use spaces in the zipname now and trigger is case insensitive

### v1.5.1 - 10.23.2018
* Unity v1.7.2 update

### v1.5 - 9.20.2018
* Unity v1.7.1 update

### v1.4.9 - 9.2.2018
* Unity v1.7 update

### v1.4.8 - 8.30.2018
* Unity v1.6.1 update

### v1.4.7 - 8.24.2018
* Unity v1.6 update

### v1.4.6 - 7.18.2018
* Added patch support for samsungs with deep_buffer contained in primary-out/primary output
* Fixed patching with busybox sed
* Unity v1.5.5 update

### v1.4.5 - 6.17.2018
* Updated for aml v1.7

### v1.4.4 - 6.15.2018
* Bug fixes

### v1.4.3 - 5.7.2018
* Unity v1.5.4 update

### v1.4.2 - 4.27.2018
* Raw patching bug fixes

### v1.4.1 - 4.26.2018
* Unity v1.5.3 update

### v1.4 - 4.23.2018
* Brought back old deep_buffer remover logic (vol key option) for the few who need it
* Minor bug fixes

### v1.1.3 - 4.16.2018
* Unity v1.5.2 update
* Add AML detection/notification

### v1.1.2 - 4.12.2018
* Reworking/fixing of audio file patching

### v1.1.1 - 4.12.2018
* Unity v1.5.1 update

### v1.1 - 3.27.2018
* Added disabling of low_latency
* Use flag of NONE for deep_buffer and low_latency, still FAST for raw

### v1.0 - 3.22.2018
* Initial release

## Source Code
* Module [GitHub](https://github.com/therealahrion/Audio-Compatibility-Patch)
