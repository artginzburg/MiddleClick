# Troubleshooting

## Accessibility permissions not working after an update

macOS may stop recognizing MiddleClick's Accessibility permission after an app update. This is a known macOS behavior — it happens because the system identifies the updated app as a different binary.

**Fix:**

1. Quit MiddleClick
2. Open `System Settings` > `Privacy & Security` > `Accessibility`
3. Remove MiddleClick from the list (select it and click `−`)
4. Open MiddleClick — it will prompt you to re-add the permission

> For more details on migrating between major versions, see [MIGRATIONS.md](./MIGRATIONS.md).

## Antivirus / CleanMyMac flags MiddleClick as adware

This is a false positive. MiddleClick uses macOS Accessibility and MultitouchSupport APIs to detect finger gestures — which is exactly the kind of system access that triggers heuristic warnings in some security tools.

MiddleClick is fully open-source — you can audit every line of code in this repository, or build from source yourself.

**Please help:** if your antivirus flags MiddleClick, report it as a false positive to the vendor. The more reports they get, the more likely they are to fix it.

- [CleanMyMac — report false positive](https://macpaw.com/support/contact) (or via the app: `CleanMyMac > Help > Contact Support`)
- For other tools, look for a "report false positive" or "submit a file for analysis" option.
