# Universal deep_buffer/raw Disabler
This fixes when streaming apps (Spotify, Pandora, etc) do not process audio effects for various equalizer applications. [More details in support thread](https://forum.xda-developers.com/apps/magisk/module-universal-deepbuffer-remover-t3577067).

## Compatibility
* Android Jellybean+
* Selinux enforcing
* All root solutions (requires init.d support if not using magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))

## Change Log
### v1.4 - 3.xx.2018
* Complete redo - now only disables deep_buffer rather than removes. Also disables raw now as well. Should fix compatibility issues

### v1.3.1 - 3.18.2018
* Unity v1.4 update

### v1.3 - 2.25.2018
* Added detection of more pol files
* Fixed vendor files in bootmode for devices with separate vendor partitions
* Fix seg faults on system installs

### v1.2 - 2.16.2018
* Add file backup on system installs
* Fine tune unity prop logic
* Update util_functions with magisk 15.4 stuff

### v1.1 - 2.10.2018
* Minor unity fixes

### v1.0 - 2.5.2018
* Initial rerelease

## Source Code
* Module [GitHub](https://github.com/therealahrion/Universal-deep_buffer-Remover)
