#!/bin/sh

show_menu(){
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"`
    ENTER_LINE=`echo "\033[33m"`
    echo -e "${MENU}TheMooseyOne Unofficial AIF${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU}     ${NUMBER} 1)${MENU} Check Tools ${NORMAL}"
    echo -e "${MENU}  *  ${NUMBER} 2)${MENU} Download ISO ${NORMAL}"
    echo -e "${MENU}    *${NUMBER} 3)${MENU} Stage 1 ${NORMAL}"
    echo -e "${MENU}* * *${NUMBER} 4)${MENU} Stage 2 ${NORMAL}"
    echo -e "${MENU}     ${NUMBER} 5)${MENU} Stage 3 ${NORMAL}"
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

clear
show_menu
while [ opt != '' ]
    do
    if [[ $opt = "" ]]; then
            exit;

    else
        case $opt in
        1) option_picked "Checking Tools";
        which curl && echo -e "${MENU}Found curl... ${NORMAL}" || echo -e "${RED_TEXT}Failed to find curl...${NORMAL}"
        which unsquashfs && echo -e "${MENU}Found unsquashfs... ${NORMAL}"|| echo -e "${RED_TEXT}Failed to find unsquashfs...${NORMAL}"
        which mdconfig && echo -e "${MENU}Found mdconfig... ${NORMAL}"|| echo -e "${RED_TEXT}Failed to find mdconfig...${NORMAL}"
        which sha1sum && echo -e "${MENU}Found md5sum... ${NORMAL}"|| echo -e "${RED_TEXT}Failed to find md5sum...${NORMAL}"
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
	curl -C - -#O "$mirror/archlinux/iso/latest/$iso" || echo -e "${RED_TEXT}Download ios failed...${NORMAL}"
	curl -C - -#O "$mirror/archlinux/iso/latest/sha1sums.txt" || echo -e "${RED_TEXT}Download sha1sums failed...${NORMAL}"
	sha1sum --check ./sha1sums.txt
	echo -e "${NUMBER}Press any key to continue...${NORMAL}"
	read -n1 -s
	clear
        show_menu;

             ;;

        3) option_picked "Starting Stage 1";
	#mdconfig -a -t vnode -f "$iso" -u 1
        #mount -t cd9660 /dev/md1 /mnt/cdrom || echo -e "${RED_TEXT}Failed to mount, check root...${NORMAL}"

	mount -o loop "$iso" /mnt/ || echo -e "${RED_TEXT}Failed to mount, check root...${NORMAL}"
	cp -v /mnt/cdrom/arch/"$arch"/airootfs.* . || echo -e "${RED_TEXT}Failed to copy squashfs...${NORMAL}"
	md5sum -c airootfs.md5
	umount /mnt || echo -e "${RED_TEXT}Unmount ISO failed...${NORMAL}"
	unsquashfs airootfs.sfs || echo -e "${RED_TEXT}Unsquash failed..${NORMAL}"
	rm -- airootfs.* || echo -e "${RED_TEXT}Failed to clean up old airootfs files...${NORMAL}"
	mkdir -p new_root  || echo -e "${RED_TEXt}Creating new_root failed...${NORMAL}"
	nbytes="$(($(du -s squashfs-root|cut -f1)+100000))K"
	mount -o size="$nbytes" -t tmpfs none ./new_root ||  echo -e "${RED_TEXT}Mounting new_root failed...${NORMAL}"
	for i in squashfs-root/*; do
        cp -r "$i" ./new_root/
        done;
	rm -r -- squashfs-root
	mkdir -p new_root/old_root
	ip a >> new_root/root/ifcfgeth
        ip r >> new_root/root/ifcfgeth
	cp ./mooseAIF.sh new_root/root/ && chmod 0755 new_root/root/mooseAIF,sh || echo -e "${RED_TEXT}Failed to move script to new_root...${NORMAL}"
	mount --make-rprivate /
	modprobe ext4 && modprobe xfs || echo -e "${RED_TEXT}Failed modprobe...${NORMAL}"
	pivot_root new_root new_root/old_root
	cd
	for i in {dev,run,sys,proc}; do
    	mount --move /old_root/"$i" /"$i"
	done
	systemctl daemon-reexec
	swapoff -a

	echo -e "${NUMBER}Verify new_root, run new_root/root/mooseAIF.sh to start Stage 2${NORMAL}"
	read -n1 -s
	clear
	exit 1;
            ;;

        4) clear;
            option_picked "Option 4 Picked";
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
