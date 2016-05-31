show_menu(){
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"`
    ENTER_LINE=`echo "\033[33m"`

    echo -e "${FGRED}SERIOUSLY DONT USE THIS, YOU WILL SOFTBRICK YOUR SYSTEM AND LOSE ALL DATA${NORMAL}"
    echo -e ""
    echo -e "${MENU}TheMooseyOne Unofficial Arch Toolkit${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU}      ${NUMBER} 1)${MENU} Check Tools ${NORMAL}"
    echo -e "${MENU}  *   ${NUMBER} 2)${MENU} Download ISO ${NORMAL}"
    echo -e "${MENU}    * ${NUMBER} 3)${MENU} Bootstrap Stage 1 ${NORMAL}"
    echo -e "${MENU}* * * ${NUMBER} 4)${MENU} Bootstrap Stage 2 ${NORMAL}"
    echo -e "${MENU}      ${NUMBER} 5)${MENU} Stage 3 ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${ENTER_LINE}Please enter a menu option and enter or ${RED_TEXT}enter to exit. ${NORMAL}"
    read opt
}
function option_picked() {
    COLOR='\033[01;31m' # bold red
    RESET='\033[00;00m' # normal white
    MESSAGE=${@:-"${RESET}Error: No message passed"}
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

function err() {
    echo -e "${RED_TEXT}$1${NORMAL}"; exit 1;
}

function wrn() {
    echo -e "${FGRED}$1${NORMAL}";
}

clear
show_menu
while [ opt != '' ]
    do
    if [[ $opt = "" ]]; then
            exit;

    else
        case $opt in
        1) option_picked "Checking Tools";
        which curl && echo -e "${MENU}Found curl... ${NORMAL}" || wrn "Failed to find curl..."
        which unsquashfs && echo -e "${MENU}Found unsquashfs... ${NORMAL}"|| wrn "Failed to find unsquashfs..."
        which sha1sum && echo -e "${MENU}Found sha1sum... ${NORMAL}"|| wrn "Failed to find sha1sum..."
	which md5sum && echo -e "${MENU}Found md5sum... ${NORMAL}" || wrn "Failed to find md5sum..."
	which vgremove && echo -e "${MENU}Found vgremove... ${NORMAL}" || wrn "Failed to find vgremove..."
	echo -e "${NUMBER}Press any key to continue...${NORMAL}"
	read -n1 -s
	clear
        show_menu;
        ;;

        2)echo -e "${NUMBER}Enter mirror to use:${NORMAL} "
	read mirror

	if [[ $mirror = "" ]]; then
        echo -e "${FGRED}No mirror selected, default is mirror.kernel.org${NORMAL}"
        mirror="http://mirrors.kernel.org"
	fi

	echo -e "${NUMBER}using mirror $mirror ${NORMAL}"

	date="$(date -u +'%Y.%m.01')"
	iso=archlinux-"$date"-dual.iso
	arch=x86_64

	echo -e "${NUMBER}Downloading ISO and checksums from $mirror ${NORMAL}"
	curl -C - -#O "$mirror/archlinux/iso/latest/$iso" || err "Download ios failed..."
	curl -C - -#O "$mirror/archlinux/iso/latest/sha1sums.txt" || err "Download sha1sums failed..."
	sha1sum --check ./sha1sums.txt
	echo -e "${NUMBER}Press any key to continue..."
	read -n1 -s
	clear
        show_menu;
             ;;

        3) option_picked "Stage 1 Start";
	mount -o loop "$iso" /mnt/ || wrn "Failed to mount, check root..."
	cp -v /mnt/arch/x86_64/airootfs.* . || err "Failed to copy squashfs..."
	md5sum -c airootfs.md5 || wrn "Chechsum failed..."
	umount /mnt || wrn "Unmount ISO failed..."
	unsquashfs airootfs.sfs || err "Unsquash failed.."
	rm -- airootfs.* || wrn "Failed to clean up old airootfs files..."
	mkdir -p new_root  || err "Creating new_root failed..."
	nbytes="$(($(du -s squashfs-root|cut -f1)+100000))K"
	mount -o size="$nbytes" -t tmpfs none ./new_root ||  err "Mounting new_root failed..."
	cp -rv ./squashfs-root/ ./new_root/ || err "Failed to copy squashfs to new_root..."
	rm -r -- squashfs-root || wrn "Failed to remove squashfs..."
	
	option_picked "Creating old_root"
	mkdir -p new_root/old_root || err "Failed to create old_root..."
	
	option_picked "Copying network information"
	ip a >> new_root/root/ifcfgeth || err "Failed to get ip a info..."
        ip r >> new_root/root/ifcfgeth || err "Failed to get ip r info..."
	cp ./CaCTools.sh new_root/root/ && chmod 0755 new_root/root/CaCTools.sh || wrn "Failed to move script to new_root...${NORMAL}"
	
	option_picked "Making old root private"
	mount --make-rprivate / || err "Failed to make old root private..."
	
	option_picked "Modprobing"
	modprobe ext4 && modprobe xfs || err "Failed modprobe...${NORMAL}"
	
	option_picked "Pivot root"
	pivot_root new_root new_root/old_root || err "Failed to pivot root..."
	cd
	option_picked "Moving old root"
	for i in {dev,run,sys,proc}; do
    	mount --move /old_root/"$i" /"$i"
	done
	option_picked "Restarting daemons"
	systemctl daemon-reexec
	option_picked "Turning swap off"
	swapoff -a

	echo -e "${NUMBER}Verify new_root and and run stage2 from new_root/root/CaCTools.sh${NORMAL}"
	read -n1 -s
	clear
	exit 1;
            ;;

        4) option_picked "Stage 2 Start";
	echo -e "${NUMBER}By continuing, you are not installing Arch, and your install is${NORMAL}"
	echo -e "${NUMBER}not officially supported. You have been warned. Enter YES if you${NORMAL}"
	echo -e "${NUMBER}wish to continue...${NORMAL}"
	read
	[[ "$REPLY" != 'YES' ]] && exit 1
	option_picked "Killing pids..."
	fuser -k -m /old_root
	option_picked "Unmounting old_root"
	umount -R /old_root || err "Failed to unmount old_root"
	option_picked "Cleaning up old_root"
	rm -rf /old_root || wrn "Failed to clean up old_root"
	option_picked "Killing LVM"
	vgremove -ff localhost-vg || err "Failed to kill LVM"
	option_picked "Setting DNS to use google 8.8.8.8"
	echo 'nameserver 8.8.8.8' > /etc/resolv.conf || err "Failed to set DNS"
	option_picked "Initializing the pacman keyring"
	systemctl start haveged
	pacman-key --init
	pacman-key --populate archlinux

	#read -r -d '' partition_scheme << 'EOF'
	#label: dos
	#label-id: 0x350346e6
	#device: /dev/sda
	#unit: sectors
	#/dev/sda1 : start=2048, size=+10G, type=83, bootable
	#EOF

	option_picked "Partitioning disk"
	#sfdisk /dev/sda <<< "$partition_scheme" || err "Faield to partition disk..."

	option_picked "Formatting disk"
	mkfs.ext4 -F /dev/sda1 || err "Failed to format disk..."
	mount /dev/sda1 /mnt || err "Failed to mount sda1"

	def_package_list=('bash' 'bzip2' 'coreutils' 'device-mapper' 'diffutils' 'e2fsprogs' 'file' 
	'filesystem' 'findutils' 'gawk' 'gettext' 'grep' 'gzip'
	'inetutils' 'iproute2' 'iputils' 'less' 'licenses' 'logrotate' 'man-db'
	'man-pages' 'pacman' 'pciutils' 'perl' 'procps-ng' 'psmisc' 'sed' 'shadow'
	'sysfsutils' 'systemd-sysvcompat' 'tar' 'texinfo' 'usbutils' 'util-linux'
	'which' 'sudo' 'nftables' 'vim' 'syslinux'
	'openssh' 'tree' 'tmux' 'htop' 'lsof' 'lynx')

	option_picked "Pacstrapping"
	pacstrap /mnt "${def_package_list[@]}" || wrn 'pacstrap'
	option_picked "Installing Syslinux..."
	syslinux-install_update -i -a -m -c /mnt/ || err 'Failed to install syslinux...'
	genfstab -U /mnt >> /mnt/etc/fstab || wrn 'Failed to generate an fstab'

	option_picked "Generating Network Configuration"
	printf '[Match]\nName=ens33\n\n[Address]\n%s\n\n[Route]\n%s\n' \
    "$(ip a show dev ens33 | awk '/inet / { print "Address=" $2 "\nBroadcast=" $4 }')" \
    "$(ip r show dev ens33 | awk 'NR == 1 { print "Gateway=" $3 }')" > /mnt/etc/systemd/network/wired.network
	
	option_picked "Generating Locale"
	locale-gen || err "Failed to generate locale"
	show_menu;
            ;;

        x)exit;
        ;;

        \n)exit;
        ;;

        *)clear;
        option_picked "Pick an option from the menu";
        show_menu;
        ;;
    esac
fi
done
