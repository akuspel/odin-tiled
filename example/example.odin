package main

import tiled "../tiled"
import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(800, 600, "Tiled Example")

	tiled_map := tiled.parse_tilemap("tileMap.json")

	tileset_texture := rl.LoadTexture("tiles.png")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_map(tiled_map, tileset_texture)
		rl.EndDrawing()
	}
}

draw_map :: proc(t_map: ^tiled.Map, texture: rl.Texture2D) {
    for layer in t_map.layers {
        for y in 0..<layer.height {
            for x in 0..<layer.width {
                gid := layer.data[y * layer.width + x]
                if gid == 0 {
                    continue
                }
                tile_x := (gid - 1) % u32(texture.width / t_map.tile_width)
                tile_y := (gid - 1) / u32(texture.width / t_map.tile_width)
                
                src_rect := rl.Rectangle{
                    x = f32(tile_x * u32(t_map.tile_width)),
                    y = f32(tile_y * u32(t_map.tile_height)),
                    width = f32(t_map.tile_width),
                    height = f32(t_map.tile_height),
                }

                dst_rect := rl.Rectangle{
                    x = f32(x * t_map.tile_width),
                    y = f32(y * t_map.tile_height),
                    width = f32(t_map.tile_width),
                    height = f32(t_map.tile_height),
                }

                rl.DrawTexturePro(texture, src_rect, dst_rect, rl.Vector2{0, 0}, 0, rl.Color{255, 255, 255, 255})
            }
        }
    }
}