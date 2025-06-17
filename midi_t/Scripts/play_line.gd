extends Area2D

# 播放线的可视化绘制
var line_color: Color = Color.WHITE
var line_width: float = 3.0
var track_width: float = 1500.0

func _ready() -> void:
	# 设置播放线的位置
	position.y = 500.0  # 对应main.gd中的Y_PLAY_LINE常量
	queue_redraw()

func _draw() -> void:
	# 绘制横跨整个轨道宽度的播放线
	var start_point = Vector2(-track_width / 2, 0)
	var end_point = Vector2(track_width / 2, 0)
	
	draw_line(start_point, end_point, line_color, line_width)
	
	# 可选：添加一些装饰效果，比如中心标记
	var center_mark_size = 10.0
	draw_line(
		Vector2(0, -center_mark_size), 
		Vector2(0, center_mark_size), 
		line_color, 
		line_width + 1.0
	)
