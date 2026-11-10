class_name Fx
## Shared 2D helpers: grain/vignette overlay, dark panels, buttons, shake, flash, dialogue box.

const GRAIN_SHADER := """
shader_type canvas_item;
uniform float vignette = 0.85;
uniform float grain = 0.10;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 1.0);
void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.3, 0.8, d) * vignette;
	float n = fract(sin(dot(floor(FRAGCOORD.xy / 2.0) + floor(TIME * 24.0) * 7.13, vec2(12.9898, 78.233))) * 43758.5453);
	float g = grain * (1.0 - v);
	float a = v + g;
	vec3 col = (tint.rgb * v + vec3(n) * g) / max(a, 0.001);
	COLOR = vec4(col, a);
}
"""

static var font: Font = ThemeDB.fallback_font


static func overlay(parent: Node, layer := 50) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = layer
	parent.add_child(cl)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = GRAIN_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	cl.add_child(r)
	return cl


static func panel_style(border := Color(0.55, 0.55, 0.5)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.02, 0.02, 0.92)
	s.border_color = border
	s.set_border_width_all(2)
	s.set_content_margin_all(14)
	return s


static func panel(border := Color(0.55, 0.55, 0.5)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(border))
	return p


static func label(text: String, size := 22, c := Color(0.88, 0.86, 0.8)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 21)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.35, 0.05, 0.05, 0.9)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78))
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	return b


static func bar(c: Color, width := 260.0) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(width, 14)
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1)
	var fg := StyleBoxFlat.new()
	fg.bg_color = c
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


## Shake a CanvasItem (Control or Node2D) around its current position.
static func shake(node: CanvasItem, strength := 14.0, duration := 0.35) -> void:
	var base: Vector2 = node.position
	var tw := node.create_tween()
	var steps := int(duration / 0.03)
	for i in steps:
		var k := 1.0 - float(i) / steps
		tw.tween_property(node, "position", base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.03)
	tw.tween_property(node, "position", base, 0.03)


## Full-screen colored flash.
static func flash(parent: Node, c := Color(0.7, 0, 0, 0.55), duration := 0.35) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 40
	parent.add_child(cl)
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, duration)
	tw.tween_callback(cl.queue_free)


## Radial light texture for PointLight2D.
static func light_texture(size := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t
