extends Control

const MOUNT_PATH := "/tmp/frzr_root"

var frzr := load("res://core/systems/frzr/frzr.tres") as Frzr

@onready var dialog := $%Dialog as Dialog
@onready var progress_dialog := $%ProgressDialog as ProgressDialog


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	run()


## Run the installer
func run():
	if not DirAccess.dir_exists_absolute("/sys/firmware/efi/efivars"):
		var msg := "Legacy BIOS installs are not supported. You must boot the installer in UEFI mode.\n\n" + \
			"Would you like to restart the computer now?"
		dialog.open(msg, "Yes", "No")
		var should_reboot := await dialog.choice_selected as bool
		
		if should_reboot:
			OS.execute("reboot", [])
			return
		
		get_tree().quit(1)
		return

	if frzr.get_available_disks().size() == 0:
		var msg := "No available disks were detected. Unable to proceed with installation. If you have an Intel CPU please make sure to turn off RST in BIOS settings."
		dialog.open(msg, "OK", "Cancel")
		await dialog.choice_selected
		
		get_tree().quit(1)
		return


## Handle back input events to exit the installer
func _input(event: InputEvent) -> void:
	if dialog.is_visible_in_tree() or progress_dialog.is_visible_in_tree():
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	
	# Only ask to exit if at the top-level menu
	var state_machine := load("res://core/ui/menus/global_state_machine.tres") as StateMachine
	if state_machine.stack_length() > 1:
		return

	var msg := "Exit the ChimeraOS installer?"
	dialog.open(msg, "No", "Yes")
	var should_continue := await dialog.choice_selected as bool
	
	if not should_continue:
		get_tree().quit(1)
		return
	var state := state_machine.pop_state()
	state_machine.push_state(state)
