# libui-ng bindings in zig

This repository is a work in progress. Libui-ng is a c library for creating
cross-platform applications using the native widget toolkits for each platform.
These bindings are a manual cleanup of the cimport of `ui.h`. Each control
type has been made an opaque with the extern functions embedded within in them.
Additionally, functions using boolean values have been converted to use `bool`.
Some helper functions have been made for writing event handlers.


## Planned Features
- [ ] Comptime function for defining a `Table` based on a struct
- [ ] Nicer bindings for event callbacks
- [ ] More examples
- [ ] Project Template
