#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure figlet is installed
if ! command -v figlet &>/dev/null; then
    echo "⚙️  'figlet' is not installed. Installing now..."
    sudo apt update -qq && sudo apt install -y figlet >/dev/null
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install figlet. Please install it manually."
        exit 1
    fi
fi

# Function to display title
function display_title() {
    clear
    echo -e "${CYAN}"
    figlet -f slant "User Manager"
    echo -e "${NC}"
}

# Function to list non-system users
function list_users() {
    echo -e "\n${GREEN}=== Current Users ===${NC}\n"
    echo -e "${YELLOW}Regular Users (UID >= 1000):${NC}"

    # Get users with UID >= 1000 (regular users, not system users)
    awk -F: '$3 >= 1000 && $1 != "nobody" {print $1 ":" $3 ":" $6}' /etc/passwd | while IFS=: read -r user uid home; do
        # Check if user has sudo
        sudo_status=""
        if groups "$user" 2>/dev/null | grep -q '\bsudo\b'; then
            sudo_status="${RED}[SUDO]${NC}"
        fi

        # Check if user is in docker group
        docker_status=""
        if groups "$user" 2>/dev/null | grep -q '\bdocker\b'; then
            docker_status="${BLUE}[DOCKER]${NC}"
        fi

        echo -e "  ${CYAN}$user${NC} (UID: $uid) $sudo_status $docker_status"
        echo -e "    Home: $home"
        echo -e "    Groups: $(groups $user 2>/dev/null | cut -d: -f2)"
    done

    echo -e "\n${YELLOW}System Users (UID < 1000) - Not recommended to remove:${NC}"
    echo -e "  Use 'cat /etc/passwd' to see all system users"
}

# Function to list groups
function list_groups() {
    echo -e "\n${GREEN}=== Current Groups ===${NC}\n"
    echo -e "${YELLOW}Custom Groups (GID >= 1000):${NC}"

    # Get groups with GID >= 1000
    awk -F: '$3 >= 1000 {print $1 ":" $3 ":" $4}' /etc/group | while IFS=: read -r group gid members; do
        echo -e "  ${CYAN}$group${NC} (GID: $gid)"
        if [[ -n "$members" ]]; then
            echo -e "    Members: $members"
        else
            echo -e "    Members: ${YELLOW}(none)${NC}"
        fi
    done

    echo -e "\n${YELLOW}Common System Groups:${NC}"
    echo -e "  docker, sudo, adm, ssh, www-data, etc."
    echo -e "  Use 'cat /etc/group' to see all groups"
}

# Function to remove user
function remove_user() {
    echo -e "\n${YELLOW}=== Remove User ===${NC}\n"

    # List users first
    list_users

    echo -e "\n${RED}WARNING: This will remove the user and optionally their home directory${NC}"
    read -p "Enter username to remove (or 'cancel' to go back): " username

    if [[ "$username" == "cancel" ]]; then
        return
    fi

    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}Error: User '$username' does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Get user info
    user_uid=$(id -u "$username")
    user_home=$(eval echo ~"$username")

    # Prevent removal of current user
    if [[ "$username" == "$(whoami)" ]]; then
        echo -e "${RED}Error: Cannot remove the currently logged-in user${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Warn if user has sudo
    if groups "$username" 2>/dev/null | grep -q '\bsudo\b'; then
        echo -e "${RED}WARNING: This user has sudo privileges!${NC}"
    fi

    # Confirm removal
    echo -e "\n${YELLOW}User details:${NC}"
    echo -e "  Username: $username"
    echo -e "  UID: $user_uid"
    echo -e "  Home: $user_home"
    echo -e "  Groups: $(groups $username 2>/dev/null | cut -d: -f2)"

    # Check if user is logged in
    echo -e "\n${YELLOW}Checking for active sessions...${NC}"
    if who | grep -q "^$username "; then
        echo -e "${RED}WARNING: User '$username' is currently logged in!${NC}"
        who | grep "^$username "
    fi

    # Check for running processes
    user_processes=$(ps -u "$username" -o pid= 2>/dev/null | wc -l)
    if [[ $user_processes -gt 0 ]]; then
        echo -e "${RED}WARNING: User '$username' has $user_processes running process(es)!${NC}"
        echo -e "\n${YELLOW}Process list:${NC}"
        ps -u "$username" -o pid,comm,args 2>/dev/null | head -20

        echo -e "\n${YELLOW}Options:${NC}"
        echo -e "  1) Kill all user processes and continue"
        echo -e "  2) Cancel and manually handle processes"
        read -p "Choose option (1/2): " process_option

        if [[ "$process_option" == "1" ]]; then
            echo -e "${YELLOW}Killing all processes for user '$username'...${NC}"
            sudo pkill -9 -u "$username" 2>/dev/null || true
            sleep 2

            # Verify processes are killed
            remaining=$(ps -u "$username" -o pid= 2>/dev/null | wc -l)
            if [[ $remaining -gt 0 ]]; then
                echo -e "${RED}Warning: $remaining process(es) still running${NC}"
            else
                echo -e "${GREEN}✓ All processes terminated${NC}"
            fi
        else
            echo -e "${YELLOW}Cancelled. Please manually terminate processes and try again.${NC}"
            echo -e "${CYAN}Tip: Use 'sudo pkill -u $username' or 'sudo killall -u $username'${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    fi

    echo -e "\n${RED}This action cannot be undone!${NC}"
    read -p "Are you sure you want to remove this user? (type 'yes' to confirm): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Ask about home directory
    read -p "Remove home directory and mail spool? (y/n): " remove_home

    # Remove user
    echo -e "\n${YELLOW}Removing user...${NC}"
    removal_error=""

    if [[ "$remove_home" =~ ^[Yy]$ ]]; then
        if sudo deluser --remove-home "$username" 2>&1 | tee /tmp/deluser_error.log; then
            echo -e "${GREEN}✓ User '$username' removed with home directory${NC}"
        else
            removal_error=$(cat /tmp/deluser_error.log)
            # Fallback to userdel if deluser fails
            if sudo userdel -r "$username" 2>&1 | tee /tmp/userdel_error.log; then
                echo -e "${GREEN}✓ User '$username' removed with home directory${NC}"
            else
                removal_error="$removal_error\n$(cat /tmp/userdel_error.log)"
                echo -e "${RED}Error: Failed to remove user${NC}"
                echo -e "\n${YELLOW}Possible reasons:${NC}"
                echo -e "  • User still has running processes"
                echo -e "  • User is logged in on another terminal"
                echo -e "  • Files are in use or locked"
                echo -e "  • User's home directory is mounted or busy"
                echo -e "\n${YELLOW}Error details:${NC}"
                echo -e "$removal_error"
                echo -e "\n${CYAN}Manual removal commands:${NC}"
                echo -e "  sudo pkill -9 -u $username     # Kill all processes"
                echo -e "  sudo userdel -r $username      # Remove user"
            fi
            rm -f /tmp/deluser_error.log /tmp/userdel_error.log
        fi
    else
        if sudo deluser "$username" 2>&1 | tee /tmp/deluser_error.log; then
            echo -e "${GREEN}✓ User '$username' removed (home directory kept at $user_home)${NC}"
        else
            removal_error=$(cat /tmp/deluser_error.log)
            # Fallback to userdel if deluser fails
            if sudo userdel "$username" 2>&1 | tee /tmp/userdel_error.log; then
                echo -e "${GREEN}✓ User '$username' removed (home directory kept at $user_home)${NC}"
            else
                removal_error="$removal_error\n$(cat /tmp/userdel_error.log)"
                echo -e "${RED}Error: Failed to remove user${NC}"
                echo -e "\n${YELLOW}Possible reasons:${NC}"
                echo -e "  • User still has running processes"
                echo -e "  • User is logged in on another terminal"
                echo -e "  • Files are in use or locked"
                echo -e "\n${YELLOW}Error details:${NC}"
                echo -e "$removal_error"
                echo -e "\n${CYAN}Manual removal commands:${NC}"
                echo -e "  sudo pkill -9 -u $username     # Kill all processes"
                echo -e "  sudo userdel $username         # Remove user"
            fi
            rm -f /tmp/deluser_error.log /tmp/userdel_error.log
        fi
    fi

    read -p "Press Enter to continue..."
}

# Function to remove group
function remove_group() {
    echo -e "\n${YELLOW}=== Remove Group ===${NC}\n"

    # List groups first
    list_groups

    echo -e "\n${RED}WARNING: Removing a group may affect user permissions${NC}"
    read -p "Enter group name to remove (or 'cancel' to go back): " groupname

    if [[ "$groupname" == "cancel" ]]; then
        return
    fi

    # Check if group exists
    if ! getent group "$groupname" &>/dev/null; then
        echo -e "${RED}Error: Group '$groupname' does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Get group info
    group_gid=$(getent group "$groupname" | cut -d: -f3)
    group_members=$(getent group "$groupname" | cut -d: -f4)

    # Warn about system groups
    if [[ $group_gid -lt 1000 ]]; then
        echo -e "${RED}WARNING: This is a system group (GID < 1000)${NC}"
        echo -e "${RED}Removing system groups can break your system!${NC}"
    fi

    # Warn about important groups
    if [[ "$groupname" =~ ^(sudo|docker|adm|ssh|root)$ ]]; then
        echo -e "${RED}CRITICAL WARNING: This is an important system group!${NC}"
        echo -e "${RED}Removing this group will likely break system functionality!${NC}"
    fi

    # Show group details
    echo -e "\n${YELLOW}Group details:${NC}"
    echo -e "  Group name: $groupname"
    echo -e "  GID: $group_gid"
    if [[ -n "$group_members" ]]; then
        echo -e "  Members: $group_members"
    else
        echo -e "  Members: ${YELLOW}(none)${NC}"
    fi

    echo -e "\n${RED}This action cannot be undone!${NC}"
    read -p "Are you sure you want to remove this group? (type 'yes' to confirm): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Remove group
    if sudo delgroup "$groupname" 2>/dev/null || sudo groupdel "$groupname" 2>/dev/null; then
        echo -e "${GREEN}✓ Group '$groupname' removed${NC}"
    else
        echo -e "${RED}Error: Failed to remove group${NC}"
        echo -e "${YELLOW}The group may be in use or you may need additional permissions${NC}"
    fi

    read -p "Press Enter to continue..."
}

# Function to remove user from group
function remove_user_from_group() {
    echo -e "\n${YELLOW}=== Remove User from Group ===${NC}\n"

    list_users
    echo ""
    list_groups

    echo ""
    read -p "Enter username: " username
    read -p "Enter group name: " groupname

    # Validate
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}Error: User '$username' does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    if ! getent group "$groupname" &>/dev/null; then
        echo -e "${RED}Error: Group '$groupname' does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Check if user is in group
    if ! groups "$username" 2>/dev/null | grep -q "\b$groupname\b"; then
        echo -e "${YELLOW}User '$username' is not in group '$groupname'${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Remove user from group
    if sudo gpasswd -d "$username" "$groupname" 2>/dev/null; then
        echo -e "${GREEN}✓ User '$username' removed from group '$groupname'${NC}"
    else
        echo -e "${RED}Error: Failed to remove user from group${NC}"
    fi

    read -p "Press Enter to continue..."
}

# Main menu
function main_menu() {
    while true; do
        display_title

        echo -e "${GREEN}User and Group Management${NC}"
        echo -e "${YELLOW}=========================${NC}\n"

        echo -e "  ${CYAN}1)${NC} List all users"
        echo -e "  ${CYAN}2)${NC} List all groups"
        echo -e "  ${CYAN}3)${NC} Remove user"
        echo -e "  ${CYAN}4)${NC} Remove group"
        echo -e "  ${CYAN}5)${NC} Remove user from group"
        echo -e "  ${CYAN}6)${NC} Exit"
        echo ""

        read -p "Choose an option (1-6): " choice

        case $choice in
            1)
                list_users
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                list_groups
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                remove_user
                ;;
            4)
                remove_group
                ;;
            5)
                remove_user_from_group
                ;;
            6)
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if running on Debian-based system
if ! grep -E 'debian|ubuntu' /etc/os-release > /dev/null 2>&1; then
    echo -e "${RED}Warning: This script is designed for Debian-based systems${NC}"
    read -p "Continue anyway? (y/n): " cont
    if [[ "$cont" != "y" ]]; then
        exit 1
    fi
fi

# Run main menu
main_menu
