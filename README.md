# odin-tiled
Loader for [Tiled]([https://ldtk.io/](https://www.mapeditor.org/)) files. Uses Odin's `core:json` to unmarshal data into structs.

## How to use
Put the `tiled.odin` file to a `tiled` folder somewhere in your project. Then you can just do this (the path might be different):
```odin
import "../tiled"
```
And then:
```odin
tiled_map := tiled.parse_tilemap(tilemap_path)
tileset_data := tiled.parse_tileset(tileset_path)
```
Thats all you need.

## Example
There is an example of a basic 2d platformer in the [example](example/) folder. It uses raylib for the tilemap rendering.

## Contributing
Contributions are welcome!
