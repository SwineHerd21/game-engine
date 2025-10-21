# ABOUT

Basic 3d game engine catered to my puzzle game.

# TO-DO

[x] Open window with X11
[ ] Handling of window events
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
    [ ] Event handling
        [ ] Keyboard input
        [ ] Pointer input
        [ ] Mouse button input
        [ ] Gain/lose focus
        [ ] Maximize/minimize
        [ ] Resize
        [ ] Custom handlers
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
    [ ] Hooking systems up to engine events
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
