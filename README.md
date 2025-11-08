# ABOUT  

Basic 3d game engine catered to my puzzle game.  

Currently runs on Linux through X11 and OpenGL.  

# TO-DO  

[x] Open window with X11  
[x] Handling of window events  
[x] 3d rendering with OpenGL  
[ ] Setup engine loop  
[ ] Debug tools (fps, camera, pause, etc.)  
[ ] Loading meshes  
[ ] ECS  
[ ] Asset management  
[ ] Sound  
[ ] Clean up code  
  [ ] Replace cImports with extern functions  
[ ] High-level API  
[ ] Windows support  

[ ] Make examples  

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
  [x] Meshes  
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
  [x] Loading assets from files  
  [ ] Memory management  
  [ ] Asset metadata in ZON format  
  [ ] Referencing assets in scenes, components and other assets (IDs?)  
  [ ] Meshes  
  [x] Shaders  
  [ ] Materials  
  [ ] Textures and sprites  
  [ ] Fonts  
  [ ] Sound files  
  [ ] Scenes  
  [ ] Compiling assets to bundles?  
[ ] Scenes/levels  
  [ ] Setting up scenes through files  
  [ ] Switching scenes  
[ ] Engine loop  
  [ ] Systems setup  
  [ ] Main loop  
      [x] Window event processing  
      [ ] Update, fixed update  
      [x] Render  
[ ] API  
  [ ] Math (vectors, matricies)  
  [ ] Accessing input  
  [ ] Asset usage  
  [ ] Event processing, updating  
  [ ] Safe wrappings to prevent low-level field access/function calls  

# BUILD  

Requires Zig 0.15.2, OpenGL 3.3+ Core  

System dependencies: libX11, libGL
Zig packages: [zigglgen](https://github.com/castholm/zigglgen)  

Build by running:  

    zig build  

Run a test window:  

    zig build run  

Run unit tests:  

    zig build test --summary all  


# Resources  

https://x.org/releases/current/doc/libX11/libX11/libX11.html - Xlib reference  
https://www.youtube.com/playlist?list=PLA0dXqQjCx0S04ntJKUftl6OaOgsiwHjA - OpenGL Tutorial  
https://learnopengl.com - OpenGL resource  
