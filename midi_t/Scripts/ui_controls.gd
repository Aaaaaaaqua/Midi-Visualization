extends Control

@onready var play_button: Button = $PlayButton
@onready var stop_button: Button = $StopButton
@onready var speed_slider: HSlider = $SpeedSlider
@onready var speed_label: Label = $SpeedLabel

var main_scene: Node2D

func _ready() -> void:
	main_scene = get_node("../")
	
	# 连接信号
	play_button.pressed.connect(_on_play_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	speed_slider.value_changed.connect(_on_speed_changed)
	
	# 设置初始值
	speed_slider.min_value = 0.1
	speed_slider.max_value = 3.0
	speed_slider.value = 1.0
	speed_slider.step = 0.1
	update_speed_label()

func _on_play_pressed() -> void:
	if main_scene and main_scene.has_method("restart_playback"):
		main_scene.restart_playback()

func _on_stop_pressed() -> void:
	if main_scene and main_scene.has_method("stop_playback"):
		main_scene.stop_playback()

func _on_speed_changed(value: float) -> void:
	if main_scene and main_scene.has_method("set_playback_speed"):
		main_scene.set_playback_speed(value)
	update_speed_label()

func update_speed_label() -> void:
	speed_label.text = "Speed: " + str(round(speed_slider.value * 100) / 100)
