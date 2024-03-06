extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player = $Player
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var laser_container = $LaserContainer
@onready var enemy_container = $EnemyContainer
@onready var hud = $UILayer/HUD
@onready var game_over_screen = $UILayer/GameOverScreen
@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var parallax_background = $ParallaxBackground
@onready var laser_sound = $SFX/LaserSound
@onready var hit_sound = $SFX/HitSound
@onready var explode_sound = $SFX/ExplodeSound

var score := 0:
	set(value):
		score = value
		hud.score = score

var high_score := 0:
	set(value):
		if value > high_score:
			high_score = value

var scroll_speed := 100

func _ready():
	var save_file = FileAccess.open("user://save.data", FileAccess.READ)
	
	if save_file != null:
		high_score = save_file.get_32()
	else:
		save_game()
	
	score = 0
	player.global_position = player_spawn_pos.global_position

func _process(delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

	elif Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
	enemy_spawn_timer.wait_time = clamp(enemy_spawn_timer.wait_time - delta * 0.005,0.5, 2)
	parallax_background.scroll_offset.y += delta * scroll_speed
	
	if parallax_background.scroll_offset.y > 960:
		parallax_background.scroll_offset.y  = 0

func _on_player_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	
	laser.global_position = location
	laser_container.add_child(laser)
	laser_sound.play()

func _on_enemy_spawn_timer_timeout():
	var enemy = enemy_scenes.pick_random().instantiate()
	
	enemy.global_position = Vector2(randf_range(50, 500), -50)
	enemy.killed.connect(_on_enemy_killed)
	enemy.hit.connect(_on_enemy_hit)
	enemy_container.add_child(enemy)

func _on_enemy_killed(points):
	score += points
	high_score = score

func _on_player_killed():
	explode_sound.play()
	game_over_screen.set_score(score)
	game_over_screen.set_high_score(high_score)
	save_game()
	await get_tree().create_timer(1.5).timeout
	game_over_screen.visible = true

func _on_enemy_hit():
	hit_sound.play()

func save_game():
	var save_file = FileAccess.open("user://save.data", FileAccess.WRITE)
	save_file.store_32(high_score)
