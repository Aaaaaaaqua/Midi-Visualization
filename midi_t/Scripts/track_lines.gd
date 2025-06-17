extends Node2D

var track_width: float = 1500.0
var min_note: int = 20
var max_note: int = 108

func _ready() -> void:
	draw_track_lines()

func draw_track_lines() -> void:
	queue_redraw()

func _draw() -> void:
	# 绘制钢琴键的轨道线
	draw_piano_layout()

func draw_piano_layout() -> void:
	var note_range: float = max_note - min_note
	
	# 绘制每个音符的轨道线
	for note_value in range(min_note, max_note + 1):
		var x_pos: float = get_note_x_position(note_value)
		var is_black_key: bool = is_black_piano_key(note_value)
		
		# 黑键用深色，白键用浅色
		var line_color: Color = Color.GRAY if is_black_key else Color.DIM_GRAY
		var line_width: float = 2.0 if is_black_key else 1.0
		
		# 绘制垂直线
		draw_line(
			Vector2(x_pos, -300),
			Vector2(x_pos, 1200),
			line_color,
			line_width
		)
	
	# 绘制八度分隔线
	for octave in range(min_note / 12, (max_note / 12) + 1):
		var x_pos: float = get_note_x_position(octave * 12)
		draw_line(
			Vector2(x_pos, -300),
			Vector2(x_pos, 1200),
			Color.WHITE,
			3.0
		)

func is_black_piano_key(note_value: int) -> bool:
	var note_in_octave: int = note_value % 12
	return note_in_octave in [1, 3, 6, 8, 10]  # C#, D#, F#, G#, A#

func get_note_x_position(note_value: int) -> float:
	var note_range: float = max_note - min_note
	var normalized_pos: float = float(note_value - min_note) / note_range
	return normalized_pos * track_width - track_width / 2
