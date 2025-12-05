# About

!!! IN DEVELOPMENT !!!

Basic 3d game engine catered to my puzzle game.

Currently runs on Linux through X11 and OpenGL.

The engine will include only the most necessary generic things that are useful everywhere: rendering, audio handling, loading assets, etc.
Stuff like game objects/entities will not be included here as their use really depends on the specific game.

# Build

Requires Zig 0.15.2, OpenGL 3.3+ Core

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
