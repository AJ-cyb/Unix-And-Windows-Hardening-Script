#!/bin/bash

log_file="/var/log/system_hardening.log"

#Welcome Function
welcome_message() {
    echo "==========================================="
    echo "Welcome to the Linux System Hardening Tool!"
    echo "==========================================="
    echo "Choose an option from the menu to apply a hardening step."
    echo "You can also choose to execute all steps at once."
    echo
# Log the current date, time, and user who ran the script
    echo "----------------------------------------" >> $log_file
    echo "Main Menu Accessed: $(date)" >> $log_file
    echo "Accessed by: ${SUDO_USER:-$(whoami)}" >> $log_file
    echo "----------------------------------------" >> $log_file
    echo
}

#Grub Protection Function
grub_protection() {
    echo "Configuring GRUB password..." | tee -a $log_file

    #Ask the user if they want to configure the GRUB password
    read -p "Do you want to configure the GRUB password? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" != "Y" && "$RESPONSE" != "y" ]]; then
        echo "GRUB password configuration canceled." | tee -a $log_file
        return
    fi


    #Prompt the user to enter the GRUB password
    read -sp "Enter GRUB password: " grub_password
    echo
    read -sp "Confirm GRUB password: " confirm_password
    echo

    #Verify that passwords match
    if [[ "$grub_password" != "$confirm_password" ]]; then
        echo "Passwords do not match. GRUB password configuration canceled." | tee -a $log_file
        return
    fi

    #Generate the hashed password
    grub_hash=$(echo -e "$grub_password\n$grub_password" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.sha512")
    if [[ -z "$grub_hash" ]]; then
        echo "Failed to generate GRUB password hash. GRUB password configuration canceled." | tee -a $log_file
        return
    fi

    #Add GRUB password and enable cryptodisk support
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
    echo "password_pbkdf2 root $grub_hash" >> /etc/grub.d/40_custom

    #Update GRUB configuration
    sudo update-grub
    echo "GRUB password configured successfully. Reboot your system to apply changes." | tee -a $log_file
}


#Kernel Hardening Function
kernel_hardening() {
    echo "Applying kernel hardening settings..." | tee -a $log_file

    #Disable kernel module loading (R4)
    read -p "Do you want to disable kernel module loading (R4)? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        echo "kernel.modules_disabled = 1" >> /etc/sysctl.conf
        echo "Disabled kernel module loading." | tee -a $log_file
    else
        echo "Skipped disabling kernel module loading." | tee -a $log_file
    fi

    #Enable Yama security module (R5)
    read -p "Do you want to enable the Yama security module (R5)? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        echo "kernel.yama.ptrace_scope = 1" >> /etc/sysctl.conf
        echo "Enabled Yama security module." | tee -a $log_file
    else
        echo "Skipped enabling Yama security module." | tee -a $log_file
    fi

    #Disable IPv6 (R6)
    read -p "Do you want to disable IPv6 (R6)? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "Disabled IPv6." | tee -a $log_file
    else
        echo "Skipped disabling IPv6." | tee -a $log_file
    fi

    #Restrict FIFO and regular file access, hard and symbolic links (R7)
    read -p "Do you want to restrict FIFO, regular file access, and links (R7)? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        echo "fs.protected_fifos = 2" >> /etc/sysctl.conf
        echo "fs.protected_regular = 2" >> /etc/sysctl.conf
        echo "fs.protected_symlinks = 1" >> /etc/sysctl.conf
        echo "fs. protected_hardinks=1" >> /etc/sysctl.conf
        echo "Restricted FIFO, regular file access, and links." | tee -a $log_file
    else
        echo "Skipped restricting FIFO, regular file access, and links." | tee -a $log_file
    fi

    #Enable IP redirection and forbid ICMP redirection
    read -p "Do you want to enable IP redirection and forbid ICMP redirection? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf  # Enable IP forwarding (redirection)
        echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_syncookies =1" >> /etc/sysctl.conf 
        echo "net.ipv4.conf.all.accept_local =0" >> /etc/sysctl.conf
        echo "Enabled IP redirection and forbidden ICMP redirects." | tee -a $log_file
    else
        echo "Skipped enabling IP redirection or forbidding ICMP redirects." | tee -a $log_file
    fi

    #Enable IOMMU
    read -p "Do you want to enable IOMMU for improved memory isolation? (Y for yes, anything else for no): " RESPONSE
    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on /' /etc/default/grub
        sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="intel_iommu=on /' /etc/default/grub
        sudo update-grub
        echo "Enabled IOMMU in GRUB configuration." | tee -a $log_file
    else
        echo "Skipped enabling IOMMU." | tee -a $log_file
    fi

    #Apply changes
    sysctl --system
    echo "Kernel hardening completed." | tee -a $log_file
}


#Password Policies Function
password_policies() {
    echo "Setting password expiration and complexity policies..." | tee -a $log_file

    #Check and install libpam-pwquality and libpwquality-tools if not installed
    echo "Checking for required packages..." | tee -a $log_file
    if ! dpkg -l | grep -q "libpam-pwquality"; then
        echo "Installing libpam-pwquality..." | tee -a $log_file
        sudo apt-get update && sudo apt-get install -y libpam-pwquality libpwquality-tools
    else
        echo "libpam-pwquality already installed." | tee -a $log_file
    fi

    if ! dpkg -l | grep -q "libpwquality-tools"; then
        echo "Installing libpwquality-tools..." | tee -a $log_file
        sudo apt-get update && sudo apt-get install -y libpwquality-tools
    else
        echo "libpwquality-tools already installed." | tee -a $log_file
    fi

    #Default values
    DEFAULT_MIN_AGE=3
    DEFAULT_MAX_AGE=180
    DEFAULT_WARN_AGE=7
    DEFAULT_MIN_LEN=12
    DEFAULT_DIFOK=3
    DEFAULT_MINCLASS=2
    DEFAULT_RETRY=3

    #Prompt the user for input with default values
    read -p "Enter minimum age for password change (default: $DEFAULT_MIN_AGE): " MIN_AGE
    read -p "Enter maximum age for password change (default: $DEFAULT_MAX_AGE): " MAX_AGE
    read -p "Enter warning age before password expiry (default: $DEFAULT_WARN_AGE): " WARN_AGE
    read -p "Enter minimum password length (default: $DEFAULT_MIN_LEN): " MIN_LEN
    read -p "Enter number of different characters required between old and new passwords (default: $DEFAULT_DIFOK): " DIFOK
    read -p "Enter minimum number of character classes (default: $DEFAULT_MINCLASS): " MINCLASS
    read -p "Enter retry limit for password changes (default: $DEFAULT_RETRY): " RETRY

    #Use default values if no input is provided
    MIN_AGE=${MIN_AGE:-$DEFAULT_MIN_AGE}
    MAX_AGE=${MAX_AGE:-$DEFAULT_MAX_AGE}
    WARN_AGE=${WARN_AGE:-$DEFAULT_WARN_AGE}
    MIN_LEN=${MIN_LEN:-$DEFAULT_MIN_LEN}
    DIFOK=${DIFOK:-$DEFAULT_DIFOK}
    MINCLASS=${MINCLASS:-$DEFAULT_MINCLASS}
    RETRY=${RETRY:-$DEFAULT_RETRY}

    #Apply password expiration policies + PAM policies
    sed -i "/^PASS_MIN_DAYS/c\PASS_MIN_DAYS   $MIN_AGE" /etc/login.defs
    sed -i "/^PASS_MAX_DAYS/c\PASS_MAX_DAYS   $MAX_AGE" /etc/login.defs
    sed -i "/^PASS_WARN_AGE/c\PASS_WARN_AGE   $WARN_AGE" /etc/login.defs
    sed -i "/pam_pwquality.so/c\password requisite pam_pwquality.so retry=$RETRY minlen=$MIN_LEN difok=$DIFOK minclass=$MINCLASS enforce_for_root" /etc/pam.d/common-password

    #Logging the changes
    echo "Password policies applied with the following settings:" | tee -a $log_file
    echo "  - Minimum Age: $MIN_AGE days" | tee -a $log_file
    echo "  - Maximum Age: $MAX_AGE days" | tee -a $log_file
    echo "  - Warning Age: $WARN_AGE days" | tee -a $log_file
    echo "  - Minimum Length: $MIN_LEN characters" | tee -a $log_file
    echo "  - Different Characters: $DIFOK" | tee -a $log_file
    echo "  - Character Classes: $MINCLASS" | tee -a $log_file
    echo "  - Retry Limit: $RETRY attempts" | tee -a $log_file
}

#Function to enable SELinux
enable_selinux() {
    echo "Enabling SELinux ..." | tee -a $log_file

    #Check if SELinux is installed
    if ! command -v sestatus &> /dev/null; then
        echo "SELinux is not installed. Installing now..." | tee -a $log_file
        sudo apt-get update
        sudo apt install policycoreutils selinux-utils selinux-basics
    else
        echo "SELinux is already installed." | tee -a $log_file
    fi

    #Ensure SELinux is enabled and in enforcing mode
    SELINUX_STATUS=$(getenforce)
    if [[ "$SELINUX_STATUS" == "Disabled" ]]; then
        echo "SELinux is currently disabled. Enabling SELinux..." | tee -a $log_file
        sudo setenforce 1
    else
        echo "SELinux is already enabled and in $SELINUX_STATUS mode." | tee -a $log_file
    fi

    #Verify SELinux status
    sestatus | tee -a $log_file
    echo "SELinux configuration completed." | tee -a $log_file
}

#UFW Firewall
configure_firewall() {
    echo "Configuring the firewall..." | tee -a $log_file

    #Check if UFW is installed
    if ! command -v ufw &> /dev/null; then
        echo "UFW is not installed. Installing now..." | tee -a $log_file
        sudo apt-get update && sudo apt-get install -y ufw
    fi

    #Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "Enabling UFW..." | tee -a $log_file
        sudo ufw enable
    fi

    #Apply basic firewall rules
    echo "Applying firewall rules..." | tee -a $log_file
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    echo "Firewall rules applied: deny incoming, allow outgoing, allow SSH, HTTP, and HTTPS." | tee -a $log_file

    #Show firewall status
    sudo ufw status verbose | tee -a $log_file
    echo "Firewall configuration completed." | tee -a $log_file
}


#System Update
system_update() {
    echo "Updating the system..." | tee -a $log_file

    #Update package lists
    echo "Updating package lists..." | tee -a $log_file
    sudo apt-get update

    #Upgrade installed packages
    echo "Upgrading installed packages..." | tee -a $log_file
    sudo apt-get upgrade -y

    #Clean up unused packages and files
    echo "Removing unnecessary packages and cleaning up..." | tee -a $log_file
    sudo apt-get autoremove -y
    sudo apt-get autoclean

    echo "System update completed successfully." | tee -a $log_file
}


#Function to execute all hardening tasks
execute_all() {
    grub_protection
    kernel_hardening
    password_policies
    enable_selinux
    configure_firewall
    echo "All hardening steps applied!" | tee -a $log_file
}

#Display the main menu
main_menu() {
    while true; do
        echo "Main Menu:"
        echo "1) GRUB Protection"
        echo "2) Kernel Hardening"
        echo "3) Password Policies"
        echo "4) Enable SELinux (This will install SELinux if not already installed)"
        echo "5) Configure Firewall (UFW)"
        echo "6) System Update"
        echo "7) Execute All Hardening Steps."
        echo "8) Exit"
        echo
        read -p "Enter your choice [1-6]: " choice
        case $choice in
            1)
                grub_protection
                ;;
            2)
                kernel_hardening
                ;;
            3)
                password_policies
                ;;
            4)
                enable_selinux
                ;;
            5) 
                configure_firewall
                ;;
            6)
                system_update
                ;;
            7)
                execute_all
                ;;
            8)
                echo "Exiting the Linux System Hardening Tool. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac

        #Ask user to return to menu or exit
        echo
        read -p "Press [Enter] to return to the main menu or type 'exit' to quit: " action
        if [[ "$action" == "exit" ]]; then
            echo "Goodbye!"
            exit 0
        fi
    done
}

#Function to check if the script is run as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "==========================================="
        echo "Welcome to the Linux System Hardening Tool!"
        echo "==========================================="
        echo "This script must be run with root privileges. Use the root account or sudo to run this script."
        exit 1
    fi
}


#Main script execution
check_root
welcome_message
main_menu

