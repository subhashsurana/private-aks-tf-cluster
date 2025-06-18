#!/bin/bash

# A wrapper script to install dependencies and run the Ansible playbook for
# setting up Azure Workload Identity Federation with GitHub Actions.
# This script creates a local Python virtual environment and manually bootstraps
# pip to bypass potential system-level `ensurepip` issues.

set -e # Exit immediately if a command exits with a non-zero status.
set -o pipefail # The return value of a pipeline is the status of the last command to exit with a non-zero status.

VENV_DIR=".venv"

# --- Helper Functions ---
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
    exit 1
}

# --- Python & Ansible Virtual Environment Setup ---
print_info "Setting up Python and Ansible virtual environment..."

# 0. Start with a clean slate by removing any previous, possibly broken, venv.
if [ -d "$VENV_DIR" ]; then
    print_warning "Removing existing '.venv' directory to ensure a clean start."
    rm -rf "$VENV_DIR"
fi

# 1. Check for Python 3
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install it to continue."
fi

# 2. Check for the venv module, essential for creating virtual environments.
if ! python3 -c "import venv" &> /dev/null; then
    print_warning "'venv' module not found for Python 3. This is common on Debian/Ubuntu."
    print_warning "Attempting to install the appropriate venv package using apt. This may require your password."
    if ! command -v apt-get &> /dev/null; then
        print_error "'apt-get' not found. Please install the Python 'venv' module for your system manually."
    fi

    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    
    sudo apt-get update
    if ! sudo apt-get install -y "python${PYTHON_VERSION}-venv"; then
        print_warning "Could not install 'python${PYTHON_VERSION}-venv'. Falling back to generic 'python3-venv'."
        if ! sudo apt-get install -y python3-venv; then
             print_error "Failed to install the venv package. Please install it manually and re-run the script."
        fi
    fi
    print_success "Successfully installed the required venv package. Please re-run the script to continue."
    exit 0
fi

# 4. Check ensurepip availability
if ! python3 -m ensurepip --version &>/dev/null; then
    print_warning "'ensurepip' is still unavailable. Falling back to manual pip bootstrap using get-pip.py..."

    # Create venv without pip
    python3 -m venv --without-pip "$VENV_DIR"

    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        print_error "Virtual environment creation failed. No activate script found."
    fi

    source "$VENV_DIR/bin/activate"

    # Download and install pip manually
    if ! command -v curl &>/dev/null; then
        print_error "'curl' is not installed. Please install it and re-run the script."
    fi

    curl -sS https://bootstrap.pypa.io/get-pip.py -o "$VENV_DIR/get-pip.py"
    python "$VENV_DIR/get-pip.py"
    rm "$VENV_DIR/get-pip.py"
    print_success "pip has been bootstrapped into the virtual environment."
else
    # Create venv normally
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
fi

# 4. Create the virtual environment with pip.
print_info "Creating Python virtual environment in './$VENV_DIR' (with pip)..."
python3 -m venv "$VENV_DIR"

# 4. Verify the virtual environment structure was created successfully.
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    print_error "Virtual environment creation failed. The '$VENV_DIR/bin/activate' script was not found. Please check your Python installation."
fi

print_info "Activating the virtual environment."
source "$VENV_DIR/bin/activate"

# 5. Manually bootstrap pip into the environment.
if ! command -v pip &> /dev/null; then
    print_warning "pip not found in venv. Bootstrapping it manually..."
    # Download the official get-pip.py script
    if ! command -v curl &> /dev/null; then
        print_error "'curl' is not installed. Please install it \(sudo apt-get install curl\) and re-run the script."
    fi
    curl -sS https://bootstrap.pypa.io/get-pip.py -o "$VENV_DIR/get-pip.py"
    # Run the bootstrap script with the venv's python
    python "$VENV_DIR/get-pip.py"
    # Clean up
    rm "$VENV_DIR/get-pip.py"
    print_success "pip has been bootstrapped into the virtual environment."
fi

# 6. Install/Verify Ansible and collections inside the virtual environment.
print_info "Checking for Ansible and required collections inside the venv..."
if ! command -v ansible &> /dev/null; then
    print_warning "Ansible not found in the venv. Installing..."
    pip install --upgrade "ansible>=2.14"
    print_success "Ansible installed."
fi

if ! ansible-galaxy collection list | grep -q 'azure.azcollection'; then
    print_warning "Ansible collection 'azure.azcollection' not found. Installing..."
    ansible-galaxy collection install azure.azcollection:>=1.16.0 --force
fi
if ! ansible-galaxy collection list | grep -q 'community.general'; then
    print_warning "Ansible collection 'community.general' not found. Installing..."
    ansible-galaxy collection install community.general
fi
print_success "Ansible environment is ready."
ansible-galaxy collection list | grep community.general


# --- Prerequisite Checks ---

# 1. Check for Azure CLI login
if ! az account show &> /dev/null; then
    print_warning "You are not logged into Azure. Please log in now."
    az login
fi
print_success "Azure CLI login confirmed."

# --- Gather Information ---
print_info "Gathering required information..."

# 1. Automatically detect Azure Subscription and Tenant ID
print_info "Fetching details from your active Azure account..."
print_info "To use a different subscription, run 'az account set --subscription <NAME_OR_ID>' and re-run this script."
AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
AZURE_TENANT_ID=$(az account show --query tenantId --output tsv)

if [[ -z "$AZURE_SUBSCRIPTION_ID" || -z "$AZURE_TENANT_ID" ]]; then
    print_error "Could not fetch Azure Subscription ID and/or Tenant ID. Please check your 'az login' status."
fi

print_success "Detected Azure Subscription ID: $AZURE_SUBSCRIPTION_ID"
print_success "Detected Azure Tenant ID:      $AZURE_TENANT_ID"

# 2. Automatically detect GitHub Owner and Repo from git remote
GIT_URL=$(git config --get remote.origin.url)
if [[ -z "$GIT_URL" ]]; then
    print_error "Could not determine git remote URL. Please run this script from within a git repository."
fi

# Parse owner and repo from HTTPS or SSH URL
if [[ "$GIT_URL" =~ github.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO="${BASH_REMATCH[2]}"
    print_success "Detected GitHub Owner: $GITHUB_OWNER"
    print_success "Detected GitHub Repo:  $GITHUB_REPO"
else
    print_error "Could not parse GitHub owner and repo from URL: $GIT_URL"
fi


# 3. Prompt for user input
read -sp "Enter your GitHub PAT (with 'repo' scope): " GITHUB_PAT
echo

# Validate input
if [[ -z "$GITHUB_PAT" ]]; then
    print_error "GitHub PAT cannot be empty."
fi

# --- Execute Ansible Playbook ---
print_info "All checks passed. Executing the Ansible playbook..."

# Export the PAT so the playbook can access it securely via lookup('env', 'GITHUB_PAT')
export GITHUB_PAT

# Assumes the playbook is named 'ansible_playbook_azure_gh.yml' and is in the same directory
ansible-playbook ansible_playbook/ansible_playbook_azure_gh.yml \
    -e "azure_subscription_id=$AZURE_SUBSCRIPTION_ID" \
    -e "azure_tenant_id=$AZURE_TENANT_ID" \
    -e "github_owner=$GITHUB_OWNER" \
    -e "github_repo=$GITHUB_REPO"

print_success "Playbook execution finished. The trust relationship should be established."

# Deactivate the virtual environment at the end of the script
deactivate

