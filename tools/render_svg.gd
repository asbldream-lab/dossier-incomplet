extends SceneTree
## Render an SVG to PNG with Godot's own rasterizer (what the game will really show).
## Usage: godot --headless -s tools/render_svg.gd -- in.svg out.png
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.new()
	var err := img.load_svg_from_buffer(FileAccess.get_file_as_bytes(a[0]), 1.0)
	print("load: ", err, " size: ", img.get_size())
	img.save_png(a[1])
	quit()
