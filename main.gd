extends Control

const MOUNT_PATH := "/tmp/frzr_root"

var frzr := load("res://core/systems/frzr/frzr.tres") as Frzr

@onready var dialog := $%Dialog as Dialog
@onready var progress_dialog := $%ProgressDialog as ProgressDialog
@onready var http := $%HTTPFileDownloader as HTTPFileDownloader


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
			#OS.execute("reboot", [])
			return
		
		get_tree().quit(1)
		return

	if frzr.get_available_disks().size() == 0:
		var msg := "No available disks were detected. Unable to proceed with installation."
		dialog.open(msg, "OK", "Cancel")
		await dialog.choice_selected
		
		get_tree().quit(1)
		return

	## TEMP
	return

	#### Test conenction or ask the user for configuration ####

	# Waiting a bit because some wifi chips are slow to scan 5GHZ networks
	await get_tree().create_timer(2).timeout

	#######################################
	
	#if OS.execute("frzr-bootstrap", ["gamer"]) != OK:
	#	var msg := "System bootstrap step failed"
	#	dialog.open(msg, "OK", "Cancel")
	#	await dialog.choice_selected
	#	get_tree().quit(1)

	# Grab the steam bootstrap for first boot
	var url := "https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/steam-jupiter-stable-1.0.0.76-1-x86_64.pkg.tar.zst"
	var tmp_pkg := "/tmp/package.pkg.tar.zst"
	var tmp_file := "/tmp/bootstraplinux_ubuntu12_32.tar.xz"
	var destination := "/tmp/frzr_root/etc/first-boot/"
	if not DirAccess.dir_exists_absolute(destination):
		DirAccess.make_dir_recursive_absolute(destination)

	http.download_file = tmp_pkg
	if http.request(url) != OK:
		var msg := "Failed to download steam bootstrap"
		dialog.open(msg, "Retry", "Cancel")
		var should_retry := await dialog.choice_selected as bool

	# Show a progress dialog for the download
	progress_dialog.value = 0
	progress_dialog.open("Downloading Steam bootstrap package")
	var on_progress := func(percent: float):
		progress_dialog.value = percent * 100
	http.progressed.connect(on_progress)
	var on_cancelled := func():
		http.cancel_request()
	progress_dialog.cancelled.connect(on_cancelled, CONNECT_ONE_SHOT)

	await http.request_completed
	http.progressed.disconnect(on_progress)
	progress_dialog.close()
	print("Download completed")
