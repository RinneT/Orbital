extends RigidBody2D
signal collision

# TODO: Internalize to clamp
var EXPLOSION_FORCE : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var body_id = get_rid()
	var state = PhysicsServer2D.body_get_direct_state(body_id)
	var gravity = state.total_gravity
	#print(gravity)

func start():
	show()
	set_deferred("freeze", true)

func release():
	set_deferred("freeze", false)
	apply_force(Vector2(0, EXPLOSION_FORCE))


func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	collision.emit()

func teleport(pos):
	# setting both the position, 
	position = pos
	# as well as performing a physics state change
	# The reason is that only changing the state induces a "lag"
	# (I assume because it is only processed on the next tick)
	# This causes issues with the Clamp collision
	# Setting the position as well when the ball is deferred seems to fix that
	PhysicsServer2D.body_set_state(
	get_rid(),
	PhysicsServer2D.BODY_STATE_TRANSFORM,
	Transform2D.IDENTITY.translated(pos))
