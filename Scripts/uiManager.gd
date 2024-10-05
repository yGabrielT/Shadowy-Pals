class_name UiManager
extends Control
var creatureLabel
@export var currentCreaturesQuant : int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	creatureLabel = get_node("creatures")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func updateCreatureCount():
	creatureLabel.text = str(currentCreaturesQuant)
