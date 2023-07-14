extends RefCounted
class_name Frzr

const MOUNT_PATH := "/tmp/frzr_root"


## Return the available disks
static func get_available_disks() -> Array[Disk]:
	var disks: Array[Disk] = []
	var output := []
	if OS.execute("lsblk", ["--list", "-n", "-o", "name,type,size,model"], output) != OK:
		print("Unable to read devices: ", output[0])
		return disks
	var stdout := output[0] as String

	# Parse the output
	for line in stdout.split("\n"):
		if not line.contains("disk"):
			continue
		var parts := line.split(" ", false, 3)
		var disk := Disk.new()
		disk.name = parts[0]
		disk.path = "/dev/" + disk.name
		disk.size = parts[2]
		disk.model = parts[3]
		disk.install_found = has_existing_install(disk.name)
		disks.append(disk)
	
	return disks


## Returns true if the block device at the given path has an existing frzr install 
static func has_existing_install(path: String) -> bool:
	var output := []
	if OS.execute("lsblk", ["-o", "label", path], output) != OK:
		print("Unable to read label from path " + path + ": " + output[0])
		return false
	var stdout := output[0] as String
	
	return stdout.contains("frzr_efi")


## Repair the installation
## https://github.com/ChimeraOS/frzr/blob/master/frzr-bootstrap
func repair_install(disk: Disk) -> Error:
	DirAccess.make_dir_recursive_absolute(MOUNT_PATH)
	
	return OK

#	mkdir -p ${MOUNT_PATH}
#	INSTALL_MOUNT=$(fdisk -o Device --list ${DISK} | grep "^${DISK}.*2$")
#	BOOT_EFI=$(fdisk -o Device --list ${DISK} | grep "^${DISK}.*1$")
#	mount ${INSTALL_MOUNT} ${MOUNT_PATH}
#	mount -t vfat ${BOOT_EFI} ${MOUNT_PATH}/boot/
#	rm -rf ${MOUNT_PATH}/boot/*
#	bootctl --esp-path=${MOUNT_PATH}/boot/ install
#
#	echo "deleting subvolume..."
#	btrfs subvolume delete ${MOUNT_PATH}/deployments/* || true
#
#	rm -rf ${MOUNT_PATH}/etc/*



class Disk:
	var name: String
	var path: String
	var model: String
	var size: String
	var install_found: bool
