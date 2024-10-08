extends CharacterBody2D


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
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
@onready var sprite := $Sprite2D
@onready var animationTree := $AnimationTree
@onready var animMouse := $FollowMouse/AnimationPlayer
var isOnAir = false
var froze;
var wasFroze
var initialSpawnpos : Vector2
var initialBagPos : Vector2
func _ready() -> void:
	initialSpawnpos = SpawnPos.position;
	initialBagPos = bag.position
	UI = get_tree().get_first_node_in_group("UI")
	print(get_parent())
	followMouse.call_deferred("reparent",get_parent())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		followMouse.global_position = event.global_position
		if(event.global_position - self.global_position).x > 0:
			self.sprite.flip_h = false
			SpawnPos.position = initialSpawnpos
			bag.position = initialBagPos
		else:
			self.sprite.flip_h = true
			SpawnPos.position = -initialSpawnpos
			bag.position = -initialBagPos
	if Input.is_action_just_released("shoot"):
		if event is InputEventMouse:
			shoot(event.position)
		
	if Input.is_action_just_released("freeze"):
		freeze()
	if Input.is_action_just_released("restart"):
		restart()
func _physics_process(delta: float) -> void:
	manageMovement(delta);
	

func _process(delta: float) -> void:
	updateAnimations()
	if followMouseArray != null:
		CheckWhichBodyIsCloserToCenter()
	if followMouseArray.is_empty():
		closestBody = null
	if followMouseArray.size() == 1:
		closestBody = followMouseArray[0]

func manageMovement(delta : float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		AudioManager.jumpPlayer_sfx.play()

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
		AudioManager.shoot_sfx.play()
		UI.currentCreaturesQuant -= 1
		UI.updateCreatureCount()
		var last = bagArray.size() - 1
		bagArray[last].global_position = SpawnPos.global_position
		#shootInstance.z_index = z_index - 1
		bagArray[last].reparent(get_parent())
		bagArray[last].freeze = false
		maskHide(bagArray[last])
		bagArray[last].apply_impulse(((mouse_pos - self.global_position).normalized()) * bulletSpeed)
		closestBody = bagArray[last]
		bagArray[last].canFreeze = true
		bagArray[last].canPick = true
		bagArray.remove_at(last)
	
func maskHide(obj):
	obj.set_collision_layer_value(2, false)
	await get_tree().create_timer(.1).timeout
	obj.set_collision_layer_value(2, true)
func freeze():
	if closestBody != null and closestBody.canFreeze:
		AudioManager.freeze_sfx.play()
		
		if !closestBody.freeze:
			froze = true
			closestBody.state = closestBody.SQUARE
		else:
			wasFroze = true
			closestBody.state = closestBody.NORMAL
		closestBody.freeze = !closestBody.freeze
		closestBody.set_collision_layer_value(1, closestBody.freeze)
	#if shootInstance == null : return
	#shootInstance.freeze = !shootInstance.freeze
	#shootInstance.set_collision_layer_value(1, shootInstance.freeze)
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("creature"):
		if body.freeze == false and body.canPick:
			body.global_position = bag.global_position
			call_deferred("freezeBody",body)
			bagArray.append(body)
			body.canFreeze = false
			body.canPick = false
			UI.currentCreaturesQuant += 1
			UI.updateCreatureCount()
			AudioManager.pick_sfx.play()

func CheckWhichBodyIsCloserToCenter():
	
	for i in followMouseArray.size():
		if closestBody != null:
			ClosestDistance = followMouse.global_position.distance_to(closestBody.global_position)
		var currentdistance = followMouse.global_position.distance_to(followMouseArray[i].global_position)
		if currentdistance < ClosestDistance:
			ClosestDistance = currentdistance
			closestBody = followMouseArray[i]
func _on_follow_mouse_body_entered(body: Node2D) -> void:
	followMouseArray.append(body)


func _on_follow_mouse_body_exited(body: Node2D) -> void:
	followMouseArray.erase(body)

func freezeBody(body):
	body.freeze = true
	body.reparent(bag)
	
func updateAnimations():
	if velocity.x != 0:
		animationTree["parameters/conditions/isWalking"] = true
		animationTree["parameters/conditions/isIdle"] = false
	else:
		animationTree["parameters/conditions/isWalking"] = false
		animationTree["parameters/conditions/isIdle"] = true
	if (Input.is_action_just_pressed("up")):
		animationTree["parameters/conditions/jump"] = true
		isOnAir = true
	else:
		animationTree["parameters/conditions/jump"] = false
	if isOnAir and is_on_floor():
		animationTree["parameters/conditions/landed"] = true
	else:
		animationTree["parameters/conditions/landed"] = false
	if froze:
		froze = false
		animationTree["parameters/conditions/freeze"] = true
		animMouse.play("lockmouse")
	else:
		animationTree["parameters/conditions/freeze"] = false
	if wasFroze:
		wasFroze = false
		animMouse.play("lockmouse",-1,-1,true)
	
func restart():
	var current_scene_file = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene_file)
