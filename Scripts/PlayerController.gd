extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var bulletSpeed := 1000
@onready var ShootObj = load("res://Scenes/tiny_creature.tscn")
@export var SpawnPos : Node2D
var shootInstance
@export var followMouse : Area2D
var followMouseArray : Array
var ClosestDistance = 10000
var closestBody;
@onready var bag :=$Bag
var bagArray : Array
var UI : Control 
func _ready() -> void:
	UI = get_tree().get_first_node_in_group("UI")
	print(get_parent())
	followMouse.call_deferred("reparent",get_parent())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		followMouse.global_position = event.global_position
	if Input.is_action_just_released("shoot"):
		shoot(event.position)
	if Input.is_action_just_released("freeze"):
		freeze()

func _physics_process(delta: float) -> void:
	manageMovement(delta);
	if followMouseArray != null:
		CheckWhichBodyIsCloserToCenter()
	if followMouseArray.is_empty():
		closestBody = null

func manageMovement(delta : float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func shoot(mouse_pos : Vector2) -> void:
	if bagArray.size() > 0:
		UI.currentCreaturesQuant -= 1
		UI.updateCreatureCount()
		var last = bagArray.size() - 1
		bagArray[last].global_position = SpawnPos.global_position
		#shootInstance.z_index = z_index - 1
		bagArray[last].reparent(get_parent())
		bagArray[last].freeze = false
		bagArray[last].apply_impulse(((mouse_pos - self.global_position).normalized()) * bulletSpeed)
		closestBody = bagArray[last]
		bagArray[last].canFreeze = true
		bagArray.remove_at(last)
	

func freeze():
	if closestBody != null and closestBody.canFreeze:
		closestBody.freeze = !closestBody.freeze
		closestBody.set_collision_layer_value(1, closestBody.freeze)
	#if shootInstance == null : return
	#shootInstance.freeze = !shootInstance.freeze
	#shootInstance.set_collision_layer_value(1, shootInstance.freeze)
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("creature"):
		if body.freeze == false:
			call_deferred("freezeBody",body)
			bagArray.append(body)
			body.global_position = bag.global_position
			body.canFreeze = false
			UI.currentCreaturesQuant += 1
			UI.updateCreatureCount()

func CheckWhichBodyIsCloserToCenter():
	
	for i in followMouseArray.size():
		if closestBody != null:
			ClosestDistance = followMouse.global_position.distance_to(closestBody.global_position)
		var currentdistance = followMouse.global_position.distance_to(followMouseArray[i].global_position)
		if currentdistance < ClosestDistance:
			ClosestDistance = currentdistance
			closestBody = followMouseArray[i]
			print(closestBody)
func _on_follow_mouse_body_entered(body: Node2D) -> void:
	followMouseArray.append(body)


func _on_follow_mouse_body_exited(body: Node2D) -> void:
	followMouseArray.erase(body)

func freezeBody(body):
	body.freeze = true
	body.reparent(bag)
