extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(RenderingServer.get_video_adapter_name())
	print(RenderingServer.get_video_adapter_type())
	print(await get_current_card_device())

func get_current_card_device() -> String:
	var cmd := Command.new("glxinfo")
	cmd.dry_run = false
	if await cmd.execute() != OK:
		return ""
	
	for line in cmd.stdout.split("\n"):
		if not "Device: " in line:
			continue
		
		# Match on the last part of the string to get the device ID
		# E.g. Device: AMD Radeon Graphics (renoir, LLVM 16.0.6, DRM 3.54, 6.5.5-arch1-1) (0x1636)
		var regex := RegEx.new()
		regex.compile("\\(0[xX][0-9a-fA-F]+\\)$")
		var result := regex.search(line)
		if not result:
			continue
		var match_str := result.get_string()

		return match_str.replace("0x", "").replace(")", "")

	return ""


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
