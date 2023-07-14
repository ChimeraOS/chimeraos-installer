extends RefCounted
class_name Command

## Convienience class for executing OS commands in a thread

var thread_pool := load("res://core/systems/threading/thread_pool.tres") as ThreadPool
var cmd: String
var args := PackedStringArray()
var stdout: String
var code := 0
var log_error := true
var dry_run := true


func _init(command: String = "", arguments: PackedStringArray = []) -> void:
	cmd = command
	args = arguments


func execute() -> int:
	thread_pool.start()
	
	# Dry run
	if dry_run:
		print("DRY RUN: ", cmd, " ", args)
		var ret := await thread_pool.exec(OS.execute.bind("sleep", [0.3])) as int
		code = ret
		return OK
	
	var output := []
	var ret := await thread_pool.exec(OS.execute.bind(cmd, args, output)) as int
	code = ret
	stdout = output[0]
	
	if log_error and code != OK:
		push_error("Failed to execute task '", cmd, " ", args, "': ", stdout)
	
	return ret
