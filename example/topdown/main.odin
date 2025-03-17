package main

import fmt "core:fmt"
import rl "vendor:raylib"
import tiled "./tiled"
import math "core:math"

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

Animation :: struct {
    texture: rl.Texture2D,
    num_frames: i32,
    frame_timer: f32,
    current_frame: i32,
    frame_length: f32,
    name: AnimationName,
}

update_animation :: proc(a: ^Animation) {
    a.frame_timer += rl.GetFrameTime()

    if a.frame_timer > a.frame_length {
        a.current_frame += 1
        a.frame_timer = 0

        if a.current_frame == a.num_frames {
            a.current_frame = 0
        }
    }
}

draw_animation :: proc(a: Animation, pos: rl.Vector2) {
    width := f32(a.texture.width)
    height := f32(a.texture.height)

    source := rl.Rectangle{
        x = f32(a.current_frame) * width / f32(a.num_frames),
        y = 0,
        width = width / f32(a.num_frames),
        height = height,
    }

    dest := rl.Rectangle{
        x = pos.x,
        y = pos.y,
        width = width / f32(a.num_frames),
        height = height,
    }

    rl.DrawTexturePro(a.texture, source, dest, 0, 0, rl.WHITE)
}

Player :: struct {
    pos: rl.Vector2,
    speed: f32,
    vel: rl.Vector2,
    idle_down: Animation,
    idle_left: Animation,
    idle_right: Animation,
    idle_up: Animation,
    walk_down: Animation,
    walk_left: Animation,
    walk_right: Animation,
    walk_up: Animation,
    collider: rl.Rectangle,
}
player: Player

tiled_map: tiled.Map

debug: bool

main :: proc() {
    rl.InitWindow(1280, 720, "simple rpg")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    debug = false

    tiled_map = tiled.parse_tilemap("res/map/map.json")
    tileset_texture := rl.LoadTexture("res/tileset/tileset.png")

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

    current_anim := &player.idle_down

    for !rl.WindowShouldClose() {
        player.vel.x = 0
        player.vel.y = 0

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

        if rl.IsKeyPressed(.TAB) {
            debug = !debug
        }

        if player.pos.x <= 0 {player.pos.x = 0}
        if player.pos.y <= 0 {player.pos.y = 0}
        
        player.pos += player.vel * player.speed * rl.GetFrameTime()

        player.collider.x = player.pos.x
        player.collider.y = player.pos.y
        player.collider.width = f32(current_anim.texture.width) / f32(current_anim.num_frames)
        player.collider.height = f32(current_anim.texture.height)

        update_animation(current_anim)

        check_map_collision()

        camera: rl.Camera2D = {
            target = {player.pos.x, player.pos.y},
            offset = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2},
            zoom = 4.0,
        }

        min_x := f32(rl.GetScreenWidth()) / (2 * camera.zoom)
        min_y := f32(rl.GetScreenHeight()) / (2 * camera.zoom)
        max_x := 1280 - min_x
        max_y := 720 - min_y

        camera.target.x = rl.Clamp(player.pos.x, min_x, max_x)
        camera.target.y = rl.Clamp(player.pos.y, min_y, max_y)

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            rl.BeginMode2D(camera)
                draw_map(tiled_map, tileset_texture)
                draw_animation(current_anim^, player.pos)

                // DEBUG LINES
                if debug {
                    rl.DrawRectangleLines(i32(player.collider.x), i32(player.collider.y), i32(player.collider.width), i32(player.collider.height), rl.GREEN)
                }
            rl.EndMode2D()

            if debug == true {
                rl.DrawText("Debug: On", 0, 0, 32, rl.WHITE)
            }
            if debug == false {
                rl.DrawText("Debug: Off", 0, 0, 32, rl.WHITE)
            }
        rl.EndDrawing()
    }
}

current_time: f32 = 0.0

draw_map :: proc(t_map: tiled.Map, texture: rl.Texture2D) {
    tile_width: i32 = 16
    tile_height: i32 = 16

    for layer in t_map.layers {
        if layer.type == "objectgroup" && layer.name == "col" {
            for obj in layer.objects {
                rect := rl.Rectangle{
                    x = f32(obj.x),
                    y = f32(obj.y),
                    width = f32(obj.width),
                    height = f32(obj.height),
                }
                // DEBUG LINES
                if debug {
                    rl.DrawRectangleLines(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height), rl.RED)
                }
            }
        }
        else if layer.type == "tilelayer" && layer.name == "background" {
            current_time += rl.GetFrameTime()

            for y in 0..<layer.height {
                for x in 0..<layer.width {
                    gid := layer.data[y * layer.width + x]
                    if gid == 0 {
                        continue
                    }
                    tile_x := i32(gid - 1) % (texture.width / tile_width)
                    tile_y := i32(gid - 1) / (texture.width / tile_height)

                    src_rect := rl.Rectangle{
                        x = f32(tile_x * tile_width),
                        y = f32(tile_y * tile_height),
                        width = f32(tile_width),
                        height = f32(tile_height),
                    }

                    dst_rect := rl.Rectangle{
                        x = f32(x * tile_width) + math.cos(current_time) * 4.0 - 4,
                        y = f32(y * tile_height) + math.sin(current_time) * 4.0 - 4,
                        width = f32(f32(tile_width) * 1.5),
                        height = f32(f32(tile_height) * 1.5),
                    }

                    rl.DrawTexturePro(texture, src_rect, dst_rect, rl.Vector2{0, 0}, 0, rl.WHITE)
                }
            }
        }
        else if layer.type == "tilelayer" {
            for y in 0..<layer.height {
                for x in 0..<layer.width {
                    gid := layer.data[y * layer.width + x]
                    if gid == 0 {
                        continue
                    }
                    tile_x := i32(gid - 1) % (texture.width / tile_width)
                    tile_y := i32(gid - 1) / (texture.width / tile_height)

                    src_rect := rl.Rectangle{
                        x = f32(tile_x * tile_width),
                        y = f32(tile_y * tile_height),
                        width = f32(tile_width),
                        height = f32(tile_height),
                    }

                    dst_rect := rl.Rectangle{
                        x = f32(x * tile_width),
                        y = f32(y * tile_height),
                        width = f32(tile_width),
                        height = f32(tile_height),
                    }

                    rl.DrawTexturePro(texture, src_rect, dst_rect, rl.Vector2{0, 0}, 0, rl.WHITE)
                }
            }
        }
    }
}

check_map_collision :: proc() {
    for layer in tiled_map.layers {
        if layer.type == "objectgroup" && layer.name == "col" {
            for obj in layer.objects {
                rect := rl.Rectangle{
                    x = f32(obj.x),
                    y = f32(obj.y),
                    width = f32(obj.width),
                    height = f32(obj.height),
                }
                if rl.CheckCollisionRecs(player.collider, rect) {
                    player.pos -= player.vel * player.speed * rl.GetFrameTime()
                }
            }
        }
    }
}
