extends Node

var bounces

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("release_ball"):
		$Clamp.release()
	if Input.is_action_pressed("retry"):
		new_game()

func new_game():
	var planets : Array[StaticBody2D] = [$Planet, $Planet2, $Planet3]
	bounces = 0
	$Clamp.start($Player_Clamp_Start.position, $Ball, planets, $Goal)
	$Ball.start()
	$Hud.update_score(bounces)
	$Background.visible = true

func goal(body):
	var ball = $Ball
	if body == ball:
		$Ball.hide()
		set_deferred("freeze", true)


func _on_ball_collision():
	bounces += 1
	$Hud.update_score(bounces)


func _on_ball_body_entered(body: Node) -> void:
	bounces += 1
	$Hud.update_score(bounces)
