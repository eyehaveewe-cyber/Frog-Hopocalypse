extends RefCounted
## Preserve the complete shared library before Classic can filter and save it.
const ERROR_TEXT := "Classic cannot protect your saved levels. Export a backup and check storage access before saving."
static func protect(legacy_path:String,nyc_path:String)->String:
	if DirAccess.dir_exists_absolute(nyc_path):return ERROR_TEXT
	if not FileAccess.file_exists(legacy_path):return ""
	var source:=FileAccess.open(legacy_path,FileAccess.READ)
	if source==null:return ERROR_TEXT
	var bytes:PackedByteArray=source.get_buffer(source.get_length())
	var read_error:=source.get_error();source.close()
	var parsed:=JSON.new()
	if read_error!=OK or parsed.parse(bytes.get_string_from_utf8())!=OK or not parsed.data is Array:return ERROR_TEXT
	if FileAccess.file_exists(nyc_path):return ""
	# A temporary copy prevents a partial destination from being accepted as a
	# complete migration on the next launch. Never replace an existing NYC file.
	var temporary:=nyc_path+".classic-copy-"+str(Time.get_ticks_usec())
	var target:=FileAccess.open(temporary,FileAccess.WRITE)
	if target==null:return ERROR_TEXT
	target.store_buffer(bytes)
	var write_error:=target.get_error();target.close()
	if write_error!=OK:
		DirAccess.remove_absolute(temporary);return ERROR_TEXT
	if FileAccess.file_exists(nyc_path):
		DirAccess.remove_absolute(temporary);return ""
	if DirAccess.rename_absolute(temporary,nyc_path)!=OK:
		DirAccess.remove_absolute(temporary);return ERROR_TEXT
	return ""
