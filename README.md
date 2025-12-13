# About

!!! IN DEVELOPMENT !!!

Basic 3d game engine catered to my puzzle game.

Currently runs on Linux through X11 and OpenGL 4.6. Tested on Linux Mint 22.1 Cinnamon.

The engine will include only the most necessary generic things that are useful everywhere: rendering, audio handling, loading assets, etc.
Stuff like game objects/entities will not be included here as their use really depends on the specific game.

# Libraries

I have a self-imposed challenge to use as little dependencies as possible. Only the windowing system, driver wrappers
(like OpenGL) and libraries for loading specific file formats (just for early convenience, maybe I will replace them later)
are allowed.

Justification for existing dependencies:

-Xlib - the windowing system, pretty necessary
-OpenGL - GPU driver API
-zigglgen - generates namespaced OpenGL bindings for convenience
-zigimg - loads various image formats from files. Also it does not have any dependencies of its own!

# Build

Requires Zig 0.15.2

System dependencies: libX11, libGL  
Zig packages: [zigglgen](https://github.com/castholm/zigglgen), [zigimg](https://github.com/zigimg/zigimg)

Build by running:

```
zig build
```

Run a test window:

```
zig build run
```

Run unit tests:

```
zig build test --summary all
```

# Resources

https://x.org/releases/current/doc/libX11/libX11/libX11.html - Xlib reference  
https://specifications.freedesktop.org/wm/latest/index.html - X11 window manager protocols  
https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions - modern OpenGL guide  
https://learnopengl.com - general OpenGL resource  
https://www.youtube.com/playlist?list=PLA0dXqQjCx0S04ntJKUftl6OaOgsiwHjA - OpenGL Tutorial  
