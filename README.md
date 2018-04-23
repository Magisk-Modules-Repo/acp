# Audio Compatibility Patch
This fixes music and streaming apps (Spotify, Pandora, etc) that aren't processing audio effects for various equalizer applications through the modification of audio policy. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

## Compatibility
* Any Android device

## Change Log
### v1.4 - 4.xx.2018
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
