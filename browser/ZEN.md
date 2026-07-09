# ZEN configuration

This document details steps to configure zen to desired behavior. Browser behavior is often changing during its development so a direct settings file is not tracked here.

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

## Middle-click autoscroll

Run `zen-preferences` after Zen has created a profile. The helper discovers
Flatpak and tarball profile roots, then writes a managed block to `user.js`.

Managed preferences:

```js
user_pref("general.autoScroll", true);
user_pref("middlemouse.paste", false);
user_pref("middlemouse.contentLoadURL", false);
user_pref("browser.tabs.searchclipboardfor.middleclick", false);
```

Restart Zen after applying. `prefs.js` is browser-managed, so the helper does
not edit it directly.
