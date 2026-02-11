# Sleepless

A macOS menu bar app that shows whether your Mac can sleep. Polls `pmset` every 5 seconds and displays a moon icon (sleep enabled) or a yellow eye icon (sleep disabled). Click to toggle, or set a timer to auto-re-enable sleep.

![demo](demo.png)

## Setup

Requires `just`, Swift 5.9+, and Xcode command line tools.

```sh
just build           # compile the app bundle
just test            # run unit tests
just run             # build and launch
just install         # build and copy to /Applications
just setup-sudoers   # install passwordless sudoers rule for pmset
just clean           # remove build artifacts
```

### Sudoers

Sleepless uses `sudo pmset disablesleep` to toggle sleep (required for lid-close prevention). Run `just setup-sudoers` to install a scoped sudoers rule that allows this without a password prompt. The `just install` command will remind you if the rule is missing.

## Manual Test Plan

1. `just build` succeeds without errors
2. `just test` — all unit tests pass
3. `just run` — app appears in menu bar with white moon icon
4. Click icon — menu shows "Sleep: Enabled" with disable options and timer presets
5. Click "Disable Sleep" — icon changes to yellow eye, menu shows "Enable Sleep"
6. Verify: `pmset -g | grep -i sleep` shows `SleepDisabled 1`
7. Click "Enable Sleep" — icon returns to white moon
8. Click "Disable Sleep for 30 min" — icon changes to yellow eye, menu shows countdown
9. While timer running, click "Enable Sleep Now" — timer cancels, sleep re-enables
10. Quit while sleep disabled — sleep is re-enabled on exit
