extends Area2D

@export var speed = 400 # Player speed
var screen_size # size of the game window
var ball : RigidBody2D # reference to the $Ball object
var PLANETS : Array[StaticBody2D]
var released # true if the Ball was released
var simulation_viewport : SubViewport

# TODO: Unify with ball
var test_ball = preload("res://ball.tscn")
var EXPLOSION_FORCE : float = 2000.0

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	create_sub_view()

# Creates a SubViewport that is used for physics prediction simulation
func create_sub_view() -> void:
	simulation_viewport = SubViewport.new()
	simulation_viewport.size = screen_size
	simulation_viewport.disable_3d = true
	var win = Window.new()
	win.add_child(simulation_viewport)
	add_child(win)
	win.hide()
	
	# Deactivate automatic physics calculation in the space
	PhysicsServer2D.space_set_active(simulation_viewport.world_2d.space, false)

func instantiate_ball(viewport: Viewport) -> RigidBody2D:
	var ball_inst = test_ball.instantiate()
	viewport.add_child(ball_inst)
	return ball_inst

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	var velocity = Vector2.ZERO
	
	# set the player velocity according to the inputs
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	# set the new position according to the velocity.
	# Clamp the position to the screen size
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# Until we release the ball, snap it to the clamp
	if (!released):
		var adapted_pos = position
		adapted_pos.y = adapted_pos.y + 100
		ball.teleport(adapted_pos)

# Function to set the players starting position and activate the player
func start(pos: Vector2, ball_obj: RigidBody2D, planets: Array[StaticBody2D]):
	released = false
	ball = ball_obj
	position = pos
	PLANETS = planets
	for planet in PLANETS:
		simulation_viewport.add_child(planet.duplicate())
	show()

func release():
	if (!released):
		ball.release()
	released = true

# Draw a prediction path of the player
func _draw() -> void:
	simulate_trajectory()
	
# Simulate the trajectory using Rapier2Ds manual step
func simulate_trajectory() -> void:
	var space : RID = simulation_viewport.world_2d.space
	var fixed_delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	# Create our simulation test ball
	var sim_ball = instantiate_ball(simulation_viewport)
	sim_ball.apply_force(Vector2(0, EXPLOSION_FORCE))
	teleport(Vector2(global_position.x, global_position.y + 100), sim_ball)
	
	# Create our line parameters
	var line_start : Vector2
	var line_end : Vector2
	var colors := [Color.RED, Color.BLUE]

	# Run the physics loop and draw the line after each step
	for i in 1000:
		line_start = sim_ball.global_position
		RapierPhysicsServer2D.space_step(space, fixed_delta)
		RapierPhysicsServer2D.space_flush_queries(space)
		line_end = sim_ball.global_position
		draw_line_global(line_start, line_end, colors[i%2])
	
	# Delete the simulation test ball
	sim_ball.queue_free()

# Draw a line using global coordinates
func draw_line_global(pointA: Vector2, pointB: Vector2, color: Color, width: int = -1) -> void:
	var local_offset := pointA - global_position
	var pointB_local := pointB - global_position
	draw_line(local_offset, pointB_local, color, width)

func teleport(pos: Vector2, object: RigidBody2D):
	# setting both the position, 
	object.position = pos
	object.global_position = pos
	# as well as performing a physics state change
	# The reason is that only changing the state induces a "lag"
	# (I assume because it is only processed on the next tick)
	# This causes issues with the Clamp collision
	# Setting the position as well when the ball is deferred seems to fix that
	PhysicsServer2D.body_set_state(
	object.get_rid(),
	PhysicsServer2D.BODY_STATE_TRANSFORM,
	Transform2D.IDENTITY.translated(pos))
	
	# Reset velocity
	object.linear_velocity = Vector2()
