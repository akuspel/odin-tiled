package main

import fmt "core:fmt"
import rl "vendor:raylib"
import tiled "./tiled"
import math "core:math"

// Enum defining different animation states for the player
AnimationName :: enum {
    IdleDown,
    IdleLeft,
    IdleRight,
    IdleUp,
    WalkDown,
    WalkLeft,
    WalkRight,
    WalkUp,
}

// Structure to represent an animation
Animation :: struct {
    texture: rl.Texture2D   // Texture for animation frames
    num_frames: i32         // Number of frames in the animation
    frame_timer: f32        // Timer to track animation frame updates
    current_frame: i32      // Current frame index
    frame_length: f32       // Duration of each frame
    name: AnimationName     // Name of the animation state
}

// Function to update the animation, advancing frames based on time
update_animation :: proc(a: ^Animation) {
    a.frame_timer += rl.GetFrameTime()

    if a.frame_timer > a.frame_length {
        a.current_frame += 1
        a.frame_timer = 0

        if a.current_frame == a.num_frames {
            a.current_frame = 0 // Loop back to the first frame
        }
    }
}

// Function to draw the current frame of an animation
draw_animation :: proc(a: Animation, pos: rl.Vector2) {
    width := f32(a.texture.width)
    height := f32(a.texture.height)

    // Determine the portion of the texture to draw
    source := rl.Rectangle{
        x = f32(a.current_frame) * width / f32(a.num_frames),
        y = 0,
        width = width / f32(a.num_frames),
        height = height,
    }

    // Define where on screen to draw the texture
    dest := rl.Rectangle{
        x = pos.x,
        y = pos.y,
        width = width / f32(a.num_frames),
        height = height,
    }

    rl.DrawTexturePro(a.texture, source, dest, 0, 0, rl.WHITE)
}

// Structure to represent the player character
Player :: struct {
    pos: rl.Vector2         // Player position
    speed: f32              // Player movement speed
    vel: rl.Vector2         // Player velocity
    idle_down: Animation
    idle_left: Animation
    idle_right: Animation
    idle_up: Animation
    walk_down: Animation
    walk_left: Animation
    walk_right: Animation
    walk_up: Animation
    collider: rl.Rectangle  // Collision box
}
player: Player

tiled_map: tiled.Map // The game map

debug: bool // Debug mode flag

// Main function where the game loop runs
main :: proc() {
    rl.InitWindow(1280, 720, "simple rpg") // Initialize the game window
    defer rl.CloseWindow() // Ensure the window is closed when the program exits
    rl.SetTargetFPS(60) // Set game to run at 60 FPS

    debug = false // Start with debug mode disabled

    // Load the game map and textures
    tiled_map = tiled.parse_tilemap("res/map/map.json")
    tileset_texture := rl.LoadTexture("res/tileset/tileset.png")

    // Initialize player with animations
    player = Player{
        pos = {100, 100},
        speed = 70,
        idle_down = Animation{
            texture = rl.LoadTexture("res/player/player_idle_down.png"),
            num_frames = 2,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.4,
            name = .IdleDown,
        },
        idle_left = Animation{
            texture = rl.LoadTexture("res/player/player_idle_left.png"),
            num_frames = 2,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.4,
            name = .IdleLeft,
        },
        idle_right = Animation{
            texture = rl.LoadTexture("res/player/player_idle_right.png"),
            num_frames = 2,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.4,
            name = .IdleRight,
        },
        idle_up = Animation{
            texture = rl.LoadTexture("res/player/player_idle_up.png"),
            num_frames = 2,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.4,
            name = .IdleUp,
        },
        walk_down = Animation{
            texture = rl.LoadTexture("res/player/player_walk_down.png"),
            num_frames = 4,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.2,
            name = .WalkDown,
        },
        walk_left = Animation{
            texture = rl.LoadTexture("res/player/player_walk_left.png"),
            num_frames = 4,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.2,
            name = .WalkLeft,
        },
        walk_right = Animation{
            texture = rl.LoadTexture("res/player/player_walk_right.png"),
            num_frames = 4,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.2,
            name = .WalkRight,
        },
        walk_up = Animation{
            texture = rl.LoadTexture("res/player/player_walk_up.png"),
            num_frames = 4,
            frame_timer = 0,
            current_frame = 0,
            frame_length = 0.2,
            name = .WalkUp,
        },
    }

    current_anim := &player.idle_down // Start with idle animation

    // Game loop
    for !rl.WindowShouldClose() {
        player.vel.x = 0
        player.vel.y = 0

        // Handle movement input
        if rl.IsKeyDown(.W) {
            player.vel.y = -1
            current_anim = &player.walk_up
        }
        else if rl.IsKeyDown(.A) {
            player.vel.x = -1
            current_anim = &player.walk_left
        }
        else if rl.IsKeyDown(.S) {
            player.vel.y = 1
            current_anim = &player.walk_down
        }
        else if rl.IsKeyDown(.D) {
            player.vel.x = 1
            current_anim = &player.walk_right
        }
        else {
            // Switch to idle animations when stopping
            if current_anim.name == .WalkUp {
                current_anim = &player.idle_up
            } 
            else if current_anim.name == .WalkLeft {
                current_anim = &player.idle_left
            } 
            else if current_anim.name == .WalkRight {
                current_anim = &player.idle_right
            } 
            else if current_anim.name == .WalkDown {
                current_anim = &player.idle_down
            }
        }

        // Toggle debug mode
        if rl.IsKeyPressed(.TAB) {
            debug = !debug
        }

        // Prevent player from moving outside the screen
        if player.pos.x <= 0 { player.pos.x = 0 }
        if player.pos.y <= 0 { player.pos.y = 0 }
        
        // Update player position based on velocity and speed
        player.pos += player.vel * player.speed * rl.GetFrameTime()

        // Update collision box
        player.collider.x = player.pos.x
        player.collider.y = player.pos.y
        player.collider.width = f32(current_anim.texture.width) / f32(current_anim.num_frames)
        player.collider.height = f32(current_anim.texture.height)

        update_animation(current_anim) // Update animation frames

        check_map_collision() // Handle collision detection

        // Camera setup to follow player
        camera: rl.Camera2D = {
            target = {player.pos.x, player.pos.y},
            offset = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2},
            zoom = 4.0,
        }

        // Camera clamping to prevent going out of bounds
        min_x := f32(rl.GetScreenWidth()) / (2 * camera.zoom)
        min_y := f32(rl.GetScreenHeight()) / (2 * camera.zoom)
        max_x := 1280 - min_x
        max_y := 720 - min_y

        camera.target.x = rl.Clamp(player.pos.x, min_x, max_x)
        camera.target.y = rl.Clamp(player.pos.y, min_y, max_y)

        // Rendering phase
        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            rl.BeginMode2D(camera)
                draw_map(tiled_map, tileset_texture)
                draw_animation(current_anim^, player.pos)

                // Draw debug info
                if debug {
                    rl.DrawRectangleLines(i32(player.collider.x), i32(player.collider.y), i32(player.collider.width), i32(player.collider.height), rl.GREEN)
                }
            rl.EndMode2D()

        rl.EndDrawing()
    }
}
