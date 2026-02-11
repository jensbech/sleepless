# Sleepless

A macOS menu bar app that shows whether your Mac can sleep. Polls `pmset` every 5 seconds and displays a moon icon (sleep enabled) or an eye icon (sleep disabled). Click to toggle.

![demo](demo.png)

## Build & Install

Requires `just` and Xcode command line tools.

```sh
just build    # compile the app bundle
just install  # copy to /Applications
just run      # build and launch
just clean    # remove build artifacts
```
