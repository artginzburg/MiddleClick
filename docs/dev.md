## To build & run in Debug mode

```sh
make run
```

> This just allows to skip opening Xcode, useful if you're working outside of it.

## Logging

Use the `log stream` command to see logs.

### Example

```sh
log stream --predicate 'subsystem == "art.ginzburg.MiddleClick"' --style compact --level debug
```

> The `--style compact` just makes the output more readable.

> The `--level debug` shows all types of logs.

### More

You can omit `--level debug`, and that, with the current configuration, will only show errors.

Refer to [CustomLogger.swift](../MiddleClick/CustomLogger.swift) for up-to-date event levels, and categories.

### Categories

Categories allow you to filter for specific events defined by the app's code, e.g. the "schedule" category corresponds to logs for the listener restart feature.

Example:

```sh
log stream --predicate 'subsystem == "art.ginzburg.MiddleClick" && category == "schedule"' --style compact --level debug
```

This can be particularly useful when developing a new feature. You can add a new logger at [CustomLogger.swift](../MiddleClick/CustomLogger.swift), and use it in the feature's code.
