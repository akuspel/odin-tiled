package tiled

import json "core:encoding/json"
import os "core:os"


/*
	Based on the JSON Map Format for Tiled 1.2.
	https://doc.mapeditor.org/en/stable/reference/json-map-format/

	TODO:
		- This needs to be extensively tested. You can help by e.g.
		  sending me your Tiled files (as JSON) in order to give me
		  testing material.
		- Comment all fields with the description in the link above.
		  Textually separate optional fields and describe them as such.
		- Add the omitempty tag where appropriate.
*/

// parse_tilemap takes a Tiled tilemap JSON file
// and converts it into an Odin data structure.
parse_tilemap :: proc(path: string) -> ^Map {
	m := &Map{}
	jdata, ok := os.read_entire_file(path)
	if !ok {
		return nil
	}

	err := json.unmarshal(jdata, m)
	return m
}

// parse_tileset takes a Tiled tileset JSON file
// and converts it into an Odin data structure.
parse_tileset :: proc(path: string) -> ^Tileset {
	ts := &Tileset{}
	jdata, ok := os.read_entire_file(path)
	if !ok {
		return nil
	}

	err := json.unmarshal(jdata, ts)
	return ts
}

// Map describes a Tiled map.
Map :: struct {
	background_color:  string,               // Hex-formatted color (#RRGGBB or #AARRGGBB) (optional).
	height:            i32,                  // Number of tile rows.
	hex_side_length:   i32,                  // Length of the side of a hex tile in pixels.
	infinite:          bool,                 // Whether the map has infinite dimensions.
	layers:            []Layer,              // Array of Layers.
	next_layer_id:     i32,                  // Auto-increments for each layer.
	next_object_id:    i32,                  // Auto-increments for each placed object.
	orientation:       string,               // "orthogonal", "isometric", "staggered" or "hexagonal".
	properties:        []Property,           // A list of properties (name, value, type).
	render_order:      string,               // Rendering direction (orthogonal maps only).
	stagger_axis:      string,               // "x" or "y" (staggered / hexagonal maps only).
	stagger_index:     string,               // "odd" or "even" (staggered / hexagonal maps only).
	tiled_version:     string,               // The Tiled version used to save the file.
	tile_height:       i32,                  // Map grid height.
	tilesets:          []Tileset,            // Array of Tilesets.
	tile_width:        i32,                  // Map grid width.
	type:              string,               // "map" (since 1.0).
	version:           f32,                  // The JSON format version.
	width:             i32,                  // Number of tile columns.
}

Property :: struct {
	name:               string,              // Name of property
	type:               string,              // Type of property value
	value:              any,                 // Value of property
}

Layer :: struct {
	// Common
	id:                i32,                  // Incremental id - unique across all layers
	name:              string,               // Name assigned to this layer
	type:              string,               // "tilelayer, "objectgroup, "imagelayer or "group"
	visible:           bool,                 // Whether layer is shown or hidden in editor
	width:             i32,                  // Column count. Same as map width for fixed-size maps
	height:            i32,                  // Row count. Same as map height for fixed-size maps
	x:                 i32,                  // Horizontal layer offset in tiles. Always 0
	y:                 i32,                  // Vertical layer offset in tiles. Always 0
	offset_x:          f32,                  // Horizontal layer offset in pixels (default: 0)
	offset_y:          f32,                  // Vertical layer offset in pixels (default: 0)
	opacity:           f32,                  // Value between 0 and 1
	properties:        []Property,           // A list of properties (name, value, type)

	// TileLayer only
	chunks:            []Chunk,              // Array of chunks (optional, for ininite maps)
	compression:       string,               // "zlib", "gzip" or empty (default)
	data:              []u32,                  // Array or string. Array of unsigned int (GIDs) or base64-encoded data
	encoding:          string,               // "csv" (default) or "base64"

	// ObjectGroup only
	objects:           []Object,             // Array of objects
	drawOrder:         string,               // "topdown" (default) or "index"

	// Group only
	layers:            []Layer,              // Array of layers

	// ImageLayer only
	image:             string,               // Image used by this layer
	transparent_color: string,               // Hex-formatted color (#RRGGBB) (optional)
}

// Chunk is used to store the tile layer data for infinite maps.
Chunk :: struct {
	data:              any,                  // Array of unsigned int (GIDs) or base64-encoded data
	height:            i32,                  // Height in tiles
	width:             i32,                  // Width in tiles
	x:                 i32,                  // X coordinate in tiles
	y:                 i32,                  // Y coordinate in tiles
}

Object :: struct {
    id:                int,                  // Incremental id - unique across all objects
    gid:               int,                  // GID, only if object comes from a Tilemap
    name:              string,               // String assigned to name field in editor
    type:              string,               // String assigned to type field in editor
    x:                 f64,                  // X coordinate in pixels
    y:                 f64,                  // Y coordinate in pixels
    width:             f64,                  // Width in pixels, ignored if using a gid
    height:            f64,                  // Height in pixels, ignored if using a gid
    visible:           bool,                 // Whether object is shown in editor
    ellipse:           bool,                 // Used to mark an object as an ellipse
    point:             bool,                 // Used to mark an object as a point
    polygon:           []Coordinate,         // A list of x,y coordinates in pixels
    polyline:          []Coordinate,         // A list of x,y coordinates in pixels
    properties:        []Property,           // A list of properties (name, value, type)
    rotation:          f64,                  // Angle in degrees clockwise
    template:          string,               // Reference to a template file, in case object is a template instance
    text:              map[string]any,        // String key-value pairs
}

Coordinate :: struct {
	x: f32,
	y: f32,
}

Offset :: struct {
	x: f32,
	y: f32,
}

// A Tileset that associates information with each tile, like its image
// path or terrain type, may include a Tiles array property. Each tile
// has an ID property, which specifies the local ID within the tileset.
//
// For the terrain information, each value is a length-4 array where
// each element is the index of a terrain on one corner of the tile.
// The order of indices is: top-left, top-right, bottom-left, bottom-right.
Tileset :: struct {
	first_gid:         i32,                  // GID corresponding to the first tile in the set
	source:            string,               // Only used if an external tileset is referred to
	name:              string,               // Name given to this tileset
	type:              string,               // "tileset" (for tileset files, since 1.0)
	columns:           i32,                  // The number of tile columns in the tileset
	image:             string,               // Image used for tiles in this set
	image_width:       i32,                  // Width of source image in pixels
	image_height:      i32,                  // Height of source image in pixels
	margin:            i32,                  // Buffer between image edge and first tile (pixels)
	spacing:           i32,                  // Spacing between adjacent tiles in image (pixels)
	tile_count:        i32,                  // The number of tiles in this tileset
	tile_width:        i32,                  // Maximum width of tiles in this set
	tile_height:       i32,                  // Maximum height of tiles in this set
	transparent_color: string,               // Hex-formatted color (#RRGGBB) (optional)
	tile_offset:       Offset,               // https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tmx-tileoffset
	grid:              Grid,                 // (Optional) https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tmx-grid
	properties:        []Property,           // A list of properties (name, value, type)
	terrains:          []Terrain,            // Array of Terrains (optional)
	tiles:             []Tile,               // Array of Tiles (optional)
	wang_sets:         []WangSet,            // Array of Wang sets (since 1.1.5)
}

// The Grid element is only used in case of isometric orientation,
// and determines how tile overlays for terrain and collision information are rendered.
Grid :: struct {
	orientation:      string,                // "orthogonal" or "isometric"
	width:            i32,                   // Width of a grid cell
	height:           i32,                   // Height of a grid cell
}

Tile :: struct {
	id:               i32,                   // Local ID of the tile
	type:             string,                // The type of the tile (optional)
	properties:       []Property,            // A list of properties (name, value, type)
	animation:        []Frame,               // Array of Frames
	terrain:          []i32,                 // Index of terrain for each corner of tile
	image:            string,                // Image representing this tile (optional)
	image_height:     i32,                   // Height of the tile image in pixels
	image_width:      i32,                   // Width of the tile image in pixels
	object_group:     Layer,                 // Layer with type "objectgroup" (optional)
}

Frame :: struct {
	furation:         i32,                   // Frame duration in milliseconds
	tile_id:          i32,                   // Local tile ID representing this frame
}

Terrain :: struct {
	name:             string,                // Name of terrain
	tile:             i32,                   // Local ID of tile representing terrain
}

WangSet :: struct {
	corner_colors:   []WangColor,            // Array of Wang colors
	edge_colors:     []WangColor,            // Array of Wang colors
	name:            string,                 // Name of the Wang set
	tile:            i32,                    // Local ID of tile representing the Wang set
	wang_tiles:      []WangTile,             // Array of Wang tiles
}

WangColor :: struct {
	color:            string,                // Hex-formatted color (#RRGGBB or #AARRGGBB)
	name:             string,                // Name of the Wang color
	probability:      f32,                   // Probability used when randomizing
	tile:             i32,                   // Local ID of tile representing the Wang color
}

WangTile :: struct {
	tile_id:          i32,                   // Local ID of tile
	wang_id:          [8]byte,               // Array of Wang color indexes (uchar[8])
	d_flip:           bool,                  // Tile is flipped diagonally
	h_flip:           bool,                  // Tile is flipped horizontally
	v_flip:           bool,                  // Tile is flipped vertically
}

// An ObjectTemplate is written to its own file
// and referenced by any instances of that template.
ObjectTemplate :: struct {
	Type:              string,               // "template"
	Tileset:           Tileset,              // External tileset used by the template (optional)
	Object:            Object,               // The object instantiated by this template
}