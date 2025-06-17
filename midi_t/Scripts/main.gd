extends Node2D
var notes: Array = []
var note_scene: PackedScene = preload("res://Scene/Note.tscn")
var start_time: int = 0
var note_index: int = 0

# 音符轨道设置
var track_width: float = 1500.0  # 轨道总宽度，您可以根据需要调整
var min_note: int = 21           # 钢琴最低音 (A0)
var max_note: int = 108          # 钢琴最高音 (C8)

# UI元素
@onready var camera: Camera2D = $Camera2D
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

# 播放控制
var is_playing: bool = true
var playback_speed: float = 1.0
var current_time: float = 0.0 # Keep track of current music time

const SPAWN_AHEAD_TIME: float = 3.0 # 音符提前多少音乐秒生成
const Y_PLAY_LINE: float = 500.0    # 音符被视为"击中"的Y坐标
const PREPARATION_TIME: float = 3.0  # 预备时间，3秒后才开始演奏

var music_started_for_this_session: bool = false
var first_note_instance: Area2D = null

func _ready() -> void:
	if !music_player:
		print("Error: MusicPlayer node not found or audio stream not loaded.")
		
	load_notes()
	start_time = Time.get_ticks_msec()
	setup_camera()
	# 注意：音乐不再在这里自动播放

func setup_camera() -> void:
	# 设置摄像机位置，使轨道居中
	if camera:
		camera.position = Vector2(0, 300)
		camera.zoom = Vector2(0.8, 0.8)

func load_notes() -> void:
	# Ensure notes.json is at midi_t/notes.json for this path to work
	var file: FileAccess = FileAccess.open("res://not	es.json", FileAccess.READ)
	if file:
		var text: String = file.get_as_text()
		var parse_result = JSON.parse_string(text)
		if parse_result != null:
			var original_notes = parse_result
			notes = []
			# 为所有音符添加预备时间延迟
			for note in original_notes:
				var delayed_note = note.duplicate()
				delayed_note["time"] += PREPARATION_TIME
				notes.append(delayed_note)
			
			if notes.is_empty():
				print("Warning: notes.json loaded but is empty.")
			else:
				print("Successfully loaded ", notes.size(), " notes with ", PREPARATION_TIME, " seconds preparation time.")
		else:
			print("Error: Failed to parse notes.json. It might be malformed.")
			notes = [] # Ensure notes is an empty array on failure
		file.close()
	else:
		print("Error: Could not open notes.json file. Make sure it's at res://notes.json (i.e., in the midi_t folder).")
		notes = [] # Ensure notes is an empty array on failure

# 播放控制方法
func restart_playback() -> void:
	note_index = 0
	start_time = Time.get_ticks_msec()
	current_time = 0.0
	is_playing = true
	clear_all_notes() # 清除现有音符

	if music_player:
		music_player.stop() # 停止音乐
	
	music_started_for_this_session = false
	first_note_instance = null
	# playback_speed 保持不变，或按需重置

func stop_playback() -> void:
	is_playing = false
	if music_player:
		music_player.stop()

func set_playback_speed(speed: float) -> void:
	playback_speed = speed
	if music_player:
		music_player.pitch_scale = playback_speed

func clear_all_notes() -> void:
	# 删除所有音符子节点
	for child in get_children():
		if child is Area2D and child.has_method("set_note_data"):
			child.queue_free()

func _process(delta: float) -> void:
	if not is_playing:
		if music_player and music_player.playing:
			music_player.stop()
		return
		
	if is_playing and music_player and not music_player.playing and music_started_for_this_session:
		# 如果音乐应该播放但停止了（例如，音频流结束），则处理此情况
		# 对于简单的MIDI瀑布流，可能不需要复杂处理，除非想要循环等
		pass

	var elapsed_since_start: float = (Time.get_ticks_msec() - start_time) / 1000.0
	current_time = elapsed_since_start * playback_speed

	# 尝试启动音乐（当时间到达预备时间后）
	if not music_started_for_this_session and current_time >= PREPARATION_TIME:
		if music_player and music_player.stream != null:
			# 音乐从0秒开始播放，因为音符时间已经包含了预备时间延迟
			music_player.play(0.0)
			music_player.pitch_scale = playback_speed # 确保应用当前速度
		music_started_for_this_session = true

	# 生成音符
	while note_index < notes.size() and notes[note_index]["time"] <= current_time + SPAWN_AHEAD_TIME:
		spawn_note(notes[note_index])
		note_index += 1

func get_note_x_position(note_value: int) -> float:
	# 计算音符在屏幕上的X位置
	var note_range: float = max_note - min_note
	if note_range <= 0: return 0 # Avoid division by zero
	var normalized_pos: float = float(note_value - min_note) / note_range
	return normalized_pos * track_width - track_width / 2

func spawn_note(note_data: Dictionary) -> void:
	var new_note: Area2D = note_scene.instantiate()
	var x_pos: float = get_note_x_position(note_data["note"])
	
	# 计算音符应该出现的Y位置，基于它的时间和当前时间
	var note_time: float = note_data["time"]
	var time_until_play: float = note_time - current_time
	var y_pos: float = Y_PLAY_LINE - (time_until_play * 200.0) # 200是下落速度
	
	new_note.position = Vector2(x_pos, y_pos)
	new_note.set_note_data(note_data)
	if new_note.has_method("set_main_scene_reference"):
		new_note.set_main_scene_reference(self)
	add_child(new_note)

	if first_note_instance == null and is_instance_valid(new_note):
		first_note_instance = new_note

func get_playback_speed() -> float:
	return playback_speed
