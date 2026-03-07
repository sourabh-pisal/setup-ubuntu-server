#!/usr/bin/env bash
set -e

install_prerequisites() {
    echo "Installing necessary packages"
    sudo apt-get update -y
    sudo apt-get install -y docker.io docker-compose htop git tmux vim 
}

configure_github() {
    read -p "Enter your Git username: " GIT_NAME
    read -p "Enter your Git email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global pull.rebase true

    SSH_FILE="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_FILE" ]; then
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_FILE" -N ""
    fi

    echo "Copy the following SSH key and add it to your GitHub account:"
    cat "$SSH_FILE.pub"

    while true; do
        read -p "Press 'y' to continue once you have added the SSH key to GitHub: " confirm
        case "$confirm" in
            [yY]) break ;;
            *) echo "Please press 'y' to continue." ;;
        esac
    done
}

setup_dotfiles() {
    mkdir -p "$HOME/workspace"
    cd "$HOME/workspace"
    git clone --bare git@github.com:sourabh-pisal/dotfiles.git "$HOME/workspace/dotfiles"
    alias dotfiles="/usr/bin/git --git-dir=$HOME/workspace/dotfiles --work-tree=$HOME"
    /usr/bin/git --git-dir="$HOME/workspace/dotfiles" --work-tree="$HOME" switch -f mainline
    /usr/bin/git --git-dir="$HOME/workspace/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
}

setup_tailscale() {
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up
}

set_nopasswd_sudo() {
    local user="${SUDO_USER:-$USER}"
    local sudoers_file="/etc/sudoers.d/$user-nopasswd"

    if sudo grep -q "^$user " "$sudoers_file" 2>/dev/null; then
        echo "NOPASSWD already configured for $user"
        return
    fi

    echo "$user ALL=(ALL) NOPASSWD:ALL" | sudo tee "$sudoers_file" > /dev/null
    sudo chmod 0440 "$sudoers_file"
    echo "NOPASSWD sudo configured for $user"
}

set_groups() {
    local user="${SUDO_USER:-$USER}"

    ensure_group() {
        local grp="$1"
        if ! getent group "$grp" >/dev/null; then
            echo "Creating group: $grp"
            sudo groupadd "$grp"
        else
            echo "Group exists: $grp"
        fi
    }

    ensure_user_in_group() {
        local grp="$1"
        if id -nG "$user" | grep -qw "$grp"; then
            echo "User already in group: $grp"
        else
            echo "Adding $user to group: $grp"
            sudo usermod -aG "$grp" "$user"
            NEED_RELOGIN=1
        fi
    }

    NEED_RELOGIN=0

    ensure_group docker

    ensure_user_in_group docker

    if [ "$NEED_RELOGIN" -eq 1 ]; then
        echo "Group changes applied. You may need to re-login for them to take effect."
    fi
}

main() {
    install_prerequisites
    configure_github
    setup_dotfiles
    set_nopasswd_sudo
    setup_tailscale
    set_groups

    echo "Setup completed successfully!"
}

main
