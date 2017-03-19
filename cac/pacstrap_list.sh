pac_list=('bash' 'bash-complete' 'net-tools' 'linux' 'bzip2' 'coreutils' 'device-mapper' 'diffutils' 'e2fsprogs' 'file' 
'filesystem' 'findutils' 'gawk' 'gettext' 'grep' 'gzip' 'inetutils' 'iproute2' 'iputils' 'less' 'licenses' 
'logrotate' 'man-db' 'man-pages' 'pacman' 'pciutils' 'perl' 'procps-ng' 'psmisc' 'sed' 'shadow' 'sysfsutils' 
'systemd-sysvcompat' 'tar' 'texinfo' 'usbutils' 'util-linux' 'which' 'sudo' 'nftables' 'vim' 'syslinux' 'openssh' 'tree' 'tmux' 'htop' 'lsof' 'lynx')
	
echo "Pacstrapping"
pacstrap /mnt "${pac_list[@]}" || echo 'failed to pacstrap'
done
