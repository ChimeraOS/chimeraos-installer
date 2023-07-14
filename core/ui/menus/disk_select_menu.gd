extends Control

var state_machine := load("res://core/ui/menus/global_state_machine.tres") as StateMachine
var frzr := load("res://core/systems/frzr/frzr.tres") as Frzr
var disks := frzr.get_available_disks()

@onready var tree := $%Tree
@onready var next_button := $%NextButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for next button pressed
	next_button.pressed.connect(_on_next_pressed)
	
	# Only enable the next button when an item is selected
	var on_selected := func():
		next_button.disabled = false
	tree.item_selected.connect(on_selected)
	
	# Configure the tree view
	var root := tree.create_item() as TreeItem
	var columns := PackedStringArray(["Name", "Model", "Size"])
	for i in range(columns.size()):
		var column_name := columns[i]
		tree.set_column_title(i, column_name)
		tree.set_column_title_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
	
	for disk in disks:
		var disk_item := root.create_child()
		disk_item.set_text(0, disk.name)
		disk_item.set_text(1, disk.model)
		disk_item.set_text(2, disk.size)
		disk_item.set_metadata(0, disk)


func _on_next_pressed() -> void:
	var item := tree.get_selected() as TreeItem
	if not item:
		push_warning("No item was selected!")
		return
	
	# Get the disk from the selected tree item
	var disk := item.get_metadata(0) as Frzr.Disk
	print("Selected disk: " + disk.path)

	# Check if the given disk already has an installation or not
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	if disk.install_found:
		var msg := "WARNING: " + disk.name + " appears to have another system deployed, " + \
			"would you like to repair the install?"
		dialog.open(msg, "Yes", "No")
		var should_repair := await dialog.choice_selected as bool
		
		if should_repair:
			_start_repair(disk)
			return

	# Warn the user before bootstrapping
	var msg := "WARNING: " + disk.name + " will now be formatted. All data on the disk will be lost." + \
		" Do you wish to proceed?"
	dialog.open(msg, "No", "Yes")
	var should_stop := await dialog.choice_selected as bool
	if should_stop:
		next_button.grab_focus.call_deferred()
		return
	
	_start_bootstrap(disk)


# Perform the bootstrapping
func _start_bootstrap(disk: Frzr.Disk) -> void:
	print("Bootstrapping disk")
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	var progress := get_tree().get_first_node_in_group("progress_dialog") as ProgressDialog

	# Set up the progress bar
	progress.value = 0
	var on_progress := func(percent: float):
		progress.value = percent * 100
	frzr.bootstrap_progressed.connect(on_progress)
	progress.open("Bootstrapping disk")

	# Wait for the bootstrapping to complete
	var err := await frzr.bootstrap(disk)
	frzr.bootstrap_progressed.disconnect(on_progress)
	progress.close()
	if err != OK:
		var err_msg := frzr.last_error
		dialog.open("System bootstrap failed:\n" + err_msg, "OK", "Cancel")
		await dialog.choice_selected
		next_button.grab_focus.call_deferred()
		return
	
	state_machine.set_state([])


func _start_repair(disk: Frzr.Disk) -> void:
	print("Repairing install")
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	var progress := get_tree().get_first_node_in_group("progress_dialog") as ProgressDialog
	
	# Set up the progress bar
	progress.value = 0
	var on_progress := func(percent: float):
		progress.value = percent * 100
	frzr.repair_progressed.connect(on_progress)
	progress.open("Repairing installation")
	
	# Wait for the repair to complete
	var err := await frzr.repair_install(disk)
	frzr.repair_progressed.disconnect(on_progress)
	progress.close()
	if err != OK:
		var err_msg := frzr.last_error
		dialog.open("Failed to repair installation:\n" + frzr.last_error, "OK", "Cancel")
		await dialog.choice_selected
		next_button.grab_focus.call_deferred()
		return
	
	state_machine.set_state([])
