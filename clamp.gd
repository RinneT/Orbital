extends Area2D

@export var speed = 400 # Player speed
var screen_size # size of the game window
var ball : RigidBody2D # reference to the $Ball object
var PLANETS : Array[StaticBody2D]
var released # true if the Ball was released

# TODO: Unify with ball
var EXPLOSION_FORCE : float = 0.0
@onready var PHYSICS_TEST_BALL : RigidBody2D = $PhysicsPredictionBall

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size


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
	show()

func release():
	if (!released):
		ball.release()
	released = true

# Draw a prediction path of the player
func _draw() -> void:
	update_trajectory()

# Draw a line using global coordinates
func draw_line_global(pointA: Vector2, pointB: Vector2, color: Color, width: int = -1) -> void:
	var local_offset := pointA - global_position
	var pointB_local := pointB - global_position
	draw_line(local_offset, pointB_local, color, width)

# Simulate the physics process to predict the path
func update_trajectory() -> void:
	PHYSICS_TEST_BALL.hide()
	var body_id = PHYSICS_TEST_BALL.get_rid()
	var state = PhysicsServer2D.body_get_direct_state(body_id)
	PHYSICS_TEST_BALL.set_deferred("freeze", false)
		
	var line_start := Vector2(global_position.x, global_position.y + 100)
	var line_end : Vector2

	var drag : float = 0.0
	# Lower timestep value = more precise physics calculation. Engine uses 0.0166..
	var timestep := 0.0166
	# Alternating colors of the line
	var colors := [Color.RED, Color.BLUE]
	PHYSICS_TEST_BALL.global_position = line_start
	
	# Initial calculation and force application
	var gravity_vec = simulate_gravity(PHYSICS_TEST_BALL)
	var velocity : Vector2 = calculate_velocity(PHYSICS_TEST_BALL, timestep, gravity_vec, Vector2(0, EXPLOSION_FORCE))
	
	# Smooth sailing without force application from here
	# Predict until a goal is hit, or max steps
	for i : int in 500:
		#var gravity_vec = state.total_gravity
		gravity_vec = simulate_gravity(PHYSICS_TEST_BALL)
		#print("Sim: " + str(gravity_vec))
		velocity += calculate_velocity(PHYSICS_TEST_BALL, timestep, gravity_vec)
		velocity = velocity * clampf(1.0 - drag * timestep, 0, 1)
		line_end = line_start + (velocity * timestep)
		
		var collision:= PHYSICS_TEST_BALL.move_and_collide(velocity * timestep)
		# If it hits something
		if collision:
			# TODO: differentiate between bodies (calculate bounce and continue)
			# and the goal (break and finish)
			velocity = velocity.bounce(collision.get_normal())
			draw_line_global(line_start, PHYSICS_TEST_BALL.global_position, Color.YELLOW)
			line_start = PHYSICS_TEST_BALL.global_position
			continue
		
		draw_line_global(line_start, line_end, colors[i%2])
		line_start = line_end

func calculate_velocity(object: RigidBody2D, timestep: float, gravity = Vector2(), applied_force = Vector2(), constant_force = Vector2()) -> Vector2:
	return object.mass * gravity + applied_force + constant_force

# Function to simulate the gravity at a given global coordinate
# This is mostly adapted from void GodotBody2D::integrate_forces in godot_body_2d.cpp
func simulate_gravity(ball: RigidBody2D) -> Vector2:
	var planet_gravity := Vector2(0,0)
	for planet in PLANETS:
		planet_gravity += get_gravity_for_body(ball, planet)
	return planet_gravity
	#force = planet_gravity * ball.mass + appliedForce + ball.constant_force
	#return force
		
# Function to simulate the gravity at a given global coordinate
# This is mostly adapted from void GodotBody2D::integrate_forces in godot_body_2d.cpp
# and https://www.reddit.com/r/gamedev/comments/w6woww/adding_orbital_gravity_to_your_game/
func get_gravity_for_body(satellite: RigidBody2D, planet: StaticBody2D) -> Vector2:
	var planet_gravity_area : Area2D = planet.get_node("Area2D")
	var planet_gravity := Vector2(0,0)
	var gr_unit_dist : float = 0.0
	if planet_gravity_area.gravity_point:
		gr_unit_dist = planet_gravity_area.gravity_point_unit_distance
	
	# Get the direction in-between the planet and the satellite
	var v : Vector2 = planet.global_position - satellite.global_position
	
	if gr_unit_dist > 0:
		var v_length_sq = v.length_squared()
		if (v_length_sq > 0):
			var gravity_strength = planet_gravity_area.gravity * gr_unit_dist * gr_unit_dist / v_length_sq
			planet_gravity = v.normalized() * gravity_strength
	else:
		planet_gravity = v.normalized() * planet_gravity_area.gravity
	
	return planet_gravity
