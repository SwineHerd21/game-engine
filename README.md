# About

!!! IN DEVELOPMENT !!!

Basic 3d game engine catered to my puzzle game.

Currently runs on Linux through X11 and OpenGL 4.6.

The engine will include only the most necessary generic things that are useful everywhere: rendering, audio handling, loading assets, etc.
Stuff like game objects/entities will not be included here as their use really depends on the specific game.

I have a self-imposed challenge to use as little dependencies as possible. Only the windowing system, driver wrappers
(like OpenGL) and libraries for loading specific file formats (just for early convenience, maybe I will replace them later)
are allowed.

# Build

! Right now only Linux targets are supported. Tested on Linux Mint 22.1 Cinnamon.

Requires Zig 0.15.2

To compile on Ubuntu-based systems install the following packages:
- libx11-dev
- libgl-dev
- libegl-dev

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

## OpenGL

https://wikis.khronos.org/opengl/Main_Page - OpenGL wiki
https://learnopengl.com - general OpenGL resource  
https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions - modern OpenGL guide  
https://www.youtube.com/playlist?list=PLA0dXqQjCx0S04ntJKUftl6OaOgsiwHjA - OpenGL Tutorial  

## X11

https://x.org/releases/current/doc/libX11/libX11/libX11.html - Xlib reference  
https://specifications.freedesktop.org/wm/latest/index.html - X11 window manager protocols  

## EGL
https://registry.khronos.org/EGL/ - EGL reference
https://gist.github.com/mmozeiko/911347b5e3d998621295794e0ba334c4 - EGL usage with Xlib  
