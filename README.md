# ABOUT

Basic 3d game engine catered to my puzzle game.

Currently runs on Linux through X11 and OpenGL.

# TO-DO

[x] Open window with X11
[x] Handling of window events
[ ] Setup engine loop
[ ] Draw to window
[ ] 3d rendering with OpenGL
[ ] Debug tools (fps, camera, pause, etc.)
[ ] Loading meshes
[ ] ECS
[ ] Asset management
[ ] Sound
[ ] Clean up code
    [ ] Replace cImports with extern functions
[ ] High-level API
[ ] Windows support

[ ] Make THE GAME

## Engine subsystems

[ ] Windowing
    [x] Window creation
    [x] Event handling
        [x] Keyboard input
        [x] Pointer input
        [x] Mouse button input
        [x] Gain/lose focus
        [x] Resize
        [x] Custom handlers
    [ ] Fullscreen
[ ] Input
    [ ] Getting key presses/releases/states/which key/etc.
    [ ] Getting mouse button presses
    [ ] Getting pointer position
    [ ] Gamepad support?
[ ] Rendering
    [ ] Meshes
    [ ] Materials
    [ ] Textures
    [ ] Lighting?
    [ ] Post effects (bloom)
    [ ] Particles
    [ ] Text
    [ ] UI
[ ] Sound
    [ ] Playing sound
    [ ] Sound mixing
    [ ] Effects
[ ] Asset management
    [ ] Loading assets from files
    [ ] Memory management
    [ ] Asset bundles
    [ ] Passing assets to other systems
    [ ] Referencing assets in scenes, components and other assets (IDs?)
    [ ] Meshes
    [ ] Textures and sprites
    [ ] Fonts
    [ ] Sound files
    [ ] Scenes
    [ ] General data
[ ] ECS
    [ ] Entity storage based on components
    [ ] Entity querying based on components
    [ ] Systems can exist without scenes
    [ ] Systems can be contained in scenes
    [ ] Systems have functions
        [ ] onStart - when a system is created
        [ ] onEnd - when a scene is destroyed
        [ ] onUpdate - runs every frame
        [ ] onEvent - handles and consume events raised by other systems
[ ] Scenes/levels
    [ ] Setting up scenes through files
    [ ] Switching scenes
[ ] Engine loop
    [ ] Systems setup
    [ ] Start window event handler
    [ ] Main loop
        [ ] Initialization (on scene load)
        [ ] Event handlers
        [ ] Update, fixed update
        [ ] Render
[ ] API
    [ ] Math, rng, I/O, time and other utils
    [ ] Subscribing to engine events (update, fixedUpdate, start, etc.)
    [ ] Accessing input
    [ ] Custom systems
    [ ] Custom components

# Resources

https://x.org/releases/current/doc/libX11/libX11/libX11.html - Xlib reference
https://www.youtube.com/playlist?list=PLA0dXqQjCx0S04ntJKUftl6OaOgsiwHjA - OpenGL Tutorial
https://learnopengl.com - OpenGL resource
