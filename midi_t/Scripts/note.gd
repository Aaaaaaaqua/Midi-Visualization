extends Area2D

# This constant defines how many pixels correspond to one second of MIDI time
# when playback_speed is 1.0. Adjust this to control the visual scroll speed.
const PIXELS_PER_SECOND_OF_MUSIC_TIME: float = 200.0
const Y_PLAY_LINE: float = 500.0  # 播放线的Y坐标

var note_data: Dictionary = {}
@onready var color_rect: ColorRect = $ColorRect
var main_scene_ref = null

# 高亮效果相关
var is_highlighted: bool = false
var highlight_tween: Tween
var shader_material: ShaderMaterial
@onready var hdr_environment: WorldEnvironment = $HDREnvironment

func _ready() -> void:
	# 为每个音符创建独立的着色器材质实例
	if color_rect and color_rect.material is ShaderMaterial:
		# 复制材质，这样每个音符都有自己的材质实例
		shader_material = color_rect.material.duplicate()
		color_rect.material = shader_material
	
	# 设置音符颜色和大小
	if color_rect:
		color_rect.color = get_note_color()
		var note_height: float = get_note_height()
		color_rect.size = Vector2(20, note_height)
		
		# 设置锚点为底部中心，这样音符从底部开始向上延伸
		color_rect.anchor_top = 1.0
		color_rect.anchor_bottom = 1.0
		color_rect.anchor_left = 0.5
		color_rect.anchor_right = 0.5
		
		# 调整偏移，使音符正确定位
		color_rect.offset_left = -10.0
		color_rect.offset_right = 10.0
		color_rect.offset_top = -note_height
		color_rect.offset_bottom = 0.0
	else:
		print("Error: ColorRect not found in Note scene.")

func set_main_scene_reference(main_ref) -> void:
	main_scene_ref = main_ref

func set_note_data(data: Dictionary) -> void:
	note_data = data
	if color_rect:
		color_rect.color = get_note_color()
		var note_height: float = get_note_height()
		color_rect.size = Vector2(20, note_height)
		
		# 重新设置锚点和偏移
		color_rect.anchor_top = 1.0
		color_rect.anchor_bottom = 1.0
		color_rect.anchor_left = 0.5
		color_rect.anchor_right = 0.5
		
		color_rect.offset_left = -10.0
		color_rect.offset_right = 10.0
		color_rect.offset_top = -note_height
		color_rect.offset_bottom = 0.0

func get_note_height() -> float:
	if note_data.has("duration"):
		var duration = note_data["duration"]
		if duration is float or duration is int:
			return max(10.0, float(duration) * 50.0)
	return 10.0

func get_note_color() -> Color:
	if note_data.has("note"):
		var note_value: int = note_data["note"]
		if note_value < 60:
			return Color.CYAN  # 左手 - 青色
		else:
			return Color.ORANGE  # 右手 - 橙色
	return Color.WHITE

func check_play_line_collision() -> void:
	# 获取音符的碰撞箱范围
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	# 计算音符碰撞箱的实际范围
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# 获取碰撞箱的全局位置和大小
	var collision_global_pos = global_position + collision_shape.position
	var collision_size = shape.size
	
	# 计算碰撞箱的上下边界
	var collision_top = collision_global_pos.y - collision_size.y / 2
	var collision_bottom = collision_global_pos.y + collision_size.y / 2
	
	# 检查播放线是否与碰撞箱重叠
	var is_overlapping = Y_PLAY_LINE >= collision_top and Y_PLAY_LINE <= collision_bottom
	
	# 根据重叠状态控制高亮
	if is_overlapping and not is_highlighted:
		start_highlight()
	elif is_overlapping and is_highlighted:
		maintain_highlight()  # 在重叠期间持续维持高亮
	elif not is_overlapping and is_highlighted:
		stop_highlight()

func start_highlight() -> void:
	if is_highlighted or not shader_material:
		return
		
	is_highlighted = true
	
	# 创建高亮动画 - 快速到达最大亮度并保持
	if highlight_tween:
		highlight_tween.kill()
	
	highlight_tween = create_tween()
	highlight_tween.set_parallel(true)
	
	# 高亮强度动画 - 快速到达最大值
	highlight_tween.tween_method(
		func(value): shader_material.set_shader_parameter("highlight_intensity", value),
		0.0, 4.0, 0.1
	).set_ease(Tween.EASE_OUT)
	
	# 辉光半径动画 - 快速到达最大值
	highlight_tween.tween_method(
		func(value): shader_material.set_shader_parameter("glow_radius", value),
		0.1, 0.9, 0.15
	).set_ease(Tween.EASE_OUT)

func maintain_highlight() -> void:
	# 在重叠期间维持高亮状态
	if is_highlighted and shader_material:
		# 确保高亮参数保持在最大值
		shader_material.set_shader_parameter("highlight_intensity", 4.0)
		shader_material.set_shader_parameter("glow_radius", 0.9)

func stop_highlight() -> void:
	if not is_highlighted or not shader_material:
		return
		
	is_highlighted = false
	
	# 淡出高亮效果
	if highlight_tween:
		highlight_tween.kill()
	
	highlight_tween = create_tween()
	highlight_tween.set_parallel(true)
	
	highlight_tween.tween_method(
		func(value): shader_material.set_shader_parameter("highlight_intensity", value),
		shader_material.get_shader_parameter("highlight_intensity"), 0.0, 0.5
	).set_ease(Tween.EASE_IN)
	
	highlight_tween.tween_method(
		func(value): shader_material.set_shader_parameter("glow_radius", value),
		shader_material.get_shader_parameter("glow_radius"), 0.3, 0.5
	).set_ease(Tween.EASE_IN)

func _process(delta: float) -> void:
	var current_effective_speed: float = PIXELS_PER_SECOND_OF_MUSIC_TIME
	
	if main_scene_ref != null and main_scene_ref.has_method("get_playback_speed"):
		current_effective_speed *= main_scene_ref.get_playback_speed()
	
	if current_effective_speed > 0:
		position.y += current_effective_speed * delta
	
	# 检查与播放线的碰撞
	check_play_line_collision()
	
	# 音符移出屏幕后删除
	if position.y > get_viewport_rect().size.y + 200:
		queue_free()
