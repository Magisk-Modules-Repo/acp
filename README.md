# Audio Compatibility Patch
This fixes music and streaming apps (Spotify, Pandora, etc) that aren't processing audio effects for various equalizer applications through the modification of the flags for deep_buffer, raw, and low_latency and/or build props. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

## Compatibility
* Any Android Jellybean+ device

## Change Log
### v1.1 - 3.xx.2018
* Added disabling of low_latency (seen on older HTC devices instead of deep_buffer)
* Use flag of NONE for deep_buffer and low_latency, still FAST for raw
* Set deep_buffer prop to false if found

### v1.0 - 3.22.2018
* Initial release

## Source Code
* Module [GitHub](https://github.com/therealahrion/Audio-Compatibility-Patch)
