extends Control

var frzr := load("res://core/systems/frzr/frzr.tres") as Frzr

@onready var next_button := $%NextButton
@onready var checkbox_fw := $%FirmwareCheckBox
@onready var checkbox_unstable := $%UnstableCheckBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for next button pressed
	next_button.pressed.connect(_on_next_pressed)


## Invoked when the next button is pressed
func _on_next_pressed() -> void:
	# Set frzr to target unstable builds if selected
	if checkbox_unstable.button_pressed:
		frzr.target = "unstable"
	else:
		frzr.target = "stable"
	
	# Enable firmware overrides
	if checkbox_fw.button_pressed:
		print("Enabling firmware overrides...")
	
	
