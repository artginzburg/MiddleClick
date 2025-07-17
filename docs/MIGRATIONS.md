# How to migrate between major versions

> Most likely, you'll be migrating from v1/v2 to v3

1. Quit an old version of MiddleClick
2. Remove MiddleClick from the Accessibility settings
   > `System Settings...` > `Privacy & Security` > `Accessibility`
3. Enable the new version in Accessibility settings when prompted.

![](./removing%20from%20Accessibility.png)

## To be aware

### Input freeze

Tweaking the Privacy settings while the app's running may freeze macOS input: remember to quit the app beforehand.

If it happens — lock screen, wait a second, unlock, open Terminal via Spotlight Search, type `killall MiddleClick` and hit Return. If input freezes again before you succeed — lock screen and repeat the process.

### Preferences

Your MiddleClick preferences should migrate automatically. If they don't — configure manually as if installed for the first time.

<br />

---

### Explanation for developers

This migration process is actually weird and shouldn't happen in modern apps. I also don't see it ever happening after MC v3.

It is surely a result of changing the Bundle ID of the app. I suppose even changing the Development Team would be enough to make an old version dangling in the Accessibility allow-list.

#### Details about Input freeze

Using `.defaultTap` of `CGEventTapOptions` (we do that in call to `CGEvent.tapCreate`) results in all input events being routed synchronously through our listener. If the listener has lost its necessary permissions while running — the events are still going to be routed our way, though they won't actually reach our handler, and thus they'll never come out. I assume this is a performance optimization in macOS, so as to not make each event check permissions ahead of itself (which would be 100+ new checks per second). All of that are my thoughts not proven by the docs though.

Using `.listenOnly` — we wouldn't be able to replace left/right clicks performed by the system. So at best we'd have a simultaneous left + middle click.

Questions for the future:

- Why are all events frozen, given we explicitly look for (.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp)?
- Can we migrate from `CGEvent` to the more modern `NSEvent`?
