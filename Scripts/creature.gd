extends RigidBody2D
var canFreeze = true
var canPick = true
@onready var normalSprite :=$normal
@onready var squareSprite :=$Square
@onready var normalcol :=$normalCol
@onready var squarecol :=$squareCol
var state
enum
{
	NORMAL,
	SQUARE
}

func _ready() -> void:
	state = NORMAL
func _process(delta: float) -> void:
	match(state):
		NORMAL:
			
			normalSprite.visible = true;
			squareSprite.visible = false;
			normalcol.disabled = true
			squarecol.disabled = false
		SQUARE:
			normalSprite.visible = false;
			squareSprite.visible = true;
			normalcol.disabled = false
			squarecol.disabled = true
			self.rotation = 0
