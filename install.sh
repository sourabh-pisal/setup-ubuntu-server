#!/usr/bin/env bash
set -e

install_prerequisites() {
    echo "Installing necessary packages"
    sudo apt-get update -y
    sudo apt-get install -y htop git tmux vim unzip rsync
}

install_docker() {
    echo "Installing Docker"
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
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

install_aws_cli() {
    echo "Installing AWS CLI"
    local arch
    arch="$(uname -m)"
    local url
    case "$arch" in
        x86_64)  url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
        aarch64) url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
        *) echo "Unsupported architecture: $arch"; return 1 ;;
    esac

    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL "$url" -o "$tmp/awscliv2.zip"
    unzip -q "$tmp/awscliv2.zip" -d "$tmp"
    sudo "$tmp/aws/install"
    rm -rf "$tmp"

    aws --version
    aws configure
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

setup_tailscale() {
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up
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
    install_docker
    configure_github
    setup_dotfiles
    install_aws_cli
    set_nopasswd_sudo
    setup_tailscale
    set_groups

    echo "Setup completed successfully!"
}

main
