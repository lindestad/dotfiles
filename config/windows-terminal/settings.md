# Windows Terminal settings

The settings.json file is not located in a standard location, and includes machine-specific config. Therefore settings are kept as text in this file. Simply overwrite the existing field in settings.json (open Terminal --> ctr+shift+,).

```json
    "keybindings": [
        // {
        //     "id": "Terminal.CopyToClipboard",
        //     "keys": "ctrl+c"
        // },
        // {
        //     "id": "Terminal.PasteFromClipboard",
        //     "keys": "ctrl+v"
        // },
        {
            "id": "Terminal.DuplicatePaneAuto",
            "keys": "alt+shift+d"
        },
        {
            "id": "Terminal.SplitPaneRight",
            "keys": "alt+shift+o"
        },
        {
            "id": "Terminal.SplitPaneDown",
            "keys": "alt+shift+u"
        },
        {
            "id": "Terminal.SplitPaneLeft",
            "keys": "alt+shift+y"
        },
        {
            "id": "Terminal.SplitPaneUp",
            "keys": "alt+shift+i"
        },
        {
            "id": "Terminal.ClosePane",
            "keys": "alt+shift+w"
        },
        {
            "id": "Terminal.MoveFocusDown",
            "keys": "alt+shift+j"
        },
        {
            "id": "Terminal.MoveFocusUp",
            "keys": "alt+shift+k"
        },
        {
            "id": "Terminal.MoveFocusRight",
            "keys": "alt+shift+l"
        },
        {
            "id": "Terminal.MoveFocusLeft",
            "keys": "alt+shift+h"
        },
        {
            "id": "Terminal.SwapPanePrevious",
            "keys": "alt+shift+;"
        },
        {
            "id": "Terminal.ToggleFocusMode",
            "keys": "alt+shift+f"
        },
        {
            "id": "Terminal.ToggleAlwaysOnTop",
            "keys": "alt+shift+t"
        }
    ],
```

