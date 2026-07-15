# ZEN configuration

This document details steps to configure zen to desired behavior. Browser behavior is often changing during its development, so browser-managed profile files are reconciled by a helper instead of tracked directly.

## Sidebar shows tabs briefly on tab change

Settings -> Look and Feel -> Theme Settings
-> Briefly make the toolbar popup when switching or opening new tabs in compact mode
Enable.

## Tabs: ctrl-tab cycles in recent order

Settings -> Interaction
-> Ctrl+Tab cycles through tabs in recently used order
Enable.

## Compact mode

Enable compact mode for both top and side-bar.

## Managed preferences and shortcuts

Run `zen-preferences` after Zen has created a profile. The helper discovers
Flatpak and tarball profile roots, writes a managed block to `user.js`, and
updates Zen's initialized keyboard shortcuts while preserving other bindings.

Managed preferences:

```js
user_pref("general.autoScroll", true);
user_pref("middlemouse.paste", false);
user_pref("middlemouse.contentLoadURL", false);
user_pref("browser.tabs.searchclipboardfor.middleclick", false);
```

Managed shortcuts:

- `Ctrl+J`: next tab in visible list order
- `Ctrl+K`: previous tab in visible list order

The helper clears any existing `Ctrl+J` and `Ctrl+K` bindings before installing
these shortcuts. If `zen-keyboard-shortcuts.json` does not exist yet, open and
close Zen once, then rerun the helper.

Restart Zen after applying. `prefs.js` is browser-managed, so the helper does
not edit it directly. Run the helper while Zen is closed when changing keyboard
shortcuts so Zen cannot overwrite the file from its in-memory settings.
