@icon("res://assets/editor-icons/download-3-fill.svg")
extends Node
class_name HTTPFileDownloader

signal request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray)
signal progressed(percent: float)

@export var download_file := "":
	set(v):
		download_file = v
		if http_request:
			http_request.download_file = v

var http_request := HTTPRequest.new()


func _ready() -> void:
	http_request.download_file = download_file
	http_request.use_threads = true
	var on_completed := func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		request_completed.emit(result, response_code, headers, body)
	http_request.request_completed.connect(on_completed)
	add_child(http_request)


func _process(_delta: float) -> void:
	var status := http_request.get_http_client_status()
	# Only update progress if the current status is receiving the body
	if status != HTTPClient.STATUS_BODY:
		return
	if http_request.get_body_size() == -1:
		return
	var percent_downloaded: float = float(http_request.get_downloaded_bytes()) / float(http_request.get_body_size())
	progressed.emit(percent_downloaded)


func request(url: String, custom_headers: PackedStringArray = [], method: HTTPClient.Method = HTTPClient.METHOD_GET, request_data: String = "") -> Error:
	return http_request.request(url, custom_headers, method, request_data)


func cancel_request() -> void:
	http_request.cancel_request()
	request_completed.emit(-1, -1, PackedStringArray(), PackedByteArray())


func get_downloaded_bytes() -> int:
	return http_request.get_downloaded_bytes()
