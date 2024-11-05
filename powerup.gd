extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	# Cast the body as a RigidBody2D.
	# If it is not a RigidBody2D, ball will be null!
	var ball := body as RigidBody2D
	if not ball:
		return
	
	# Boost the ball by its linear velocity
	ball.apply_impulse(ball.linear_velocity)
