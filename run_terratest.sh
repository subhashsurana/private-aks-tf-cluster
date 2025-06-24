#!/bin/bash

# Exit on any error
set -e

# Check if rbenv is installed, if not install it
if ! command -v rbenv &> /dev/null; then
    echo "Installing rbenv..."
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo "rbenv installed."
fi

# Rehash rbenv to refresh environment
echo "Rehashing rbenv..."
rbenv rehash

# Install the latest Ruby version if not already installed
echo "Checking for latest Ruby version..."
LATEST_RUBY_VERSION=$(rbenv install -l | grep -v - | tail -1 | tr -d ' ')
if ! rbenv versions | grep -q "$LATEST_RUBY_VERSION"; then
    echo "Installing Ruby $LATEST_RUBY_VERSION..."
    rbenv install "$LATEST_RUBY_VERSION"
    rbenv global "$LATEST_RUBY_VERSION"
    echo "Ruby $LATEST_RUBY_VERSION installed and set as global."
else
    echo "Ruby $LATEST_RUBY_VERSION already installed."
    rbenv global "$LATEST_RUBY_VERSION"
fi

# Verify Ruby version
echo "Ruby version:"
ruby --version

# Install Terraspace if not already installed or update to the latest version
if ! gem list terraspace -i &> /dev/null; then
    echo "Installing Terraspace with the default Ruby version..."
    gem install terraspace
else
    echo "Updating Terraspace to the latest version..."
    gem update terraspace
fi

# Remove .terraspace-cache directory to ensure a clean environment
echo "Removing .terraspace-cache directory for a clean environment..."
rm -rf .terraspace-cache
echo ".terraspace-cache directory removed."

# Verify Terraspace installation
echo "Terraspace version:"
terraspace --version || echo "Terraspace installed but may require additional plugins."

# Check if Terraform is installed, if not install the latest version
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    # Install prerequisites for Terraform installation
    sudo apt-get update
    sudo apt-get install -y unzip curl
    # Get the latest Terraform version
    TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | grep -o '"current_version":"[^"]*"' | grep -o '[0-9][0-9.]*')
    echo "Latest Terraform version: $TERRAFORM_VERSION"
    curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    echo "Terraform $TERRAFORM_VERSION installed."
else
    echo "Terraform already installed."
fi

# Verify Terraform version
echo "Terraform version:"
terraform --version

# Check if Gemfile exists and run bundle install to ensure all required gems are installed
if [ -f "Gemfile" ]; then
    echo "Gemfile found, running bundle install..."
    gem install bundler
    bundle install
else
    echo "No Gemfile found, skipping bundle install."
fi

# Export environment variable to bypass Terraform licensing version check
export TS_VERSION_CHECK=0
echo "Exported TS_VERSION_CHECK=0 to bypass Terraform version check errors"

# Set environment variable for the desired environment
export TS_ENV=dev

# Navigate to the test directory
cd app/stacks/core

# Run the Terratest
echo "Running Terratest..."
go test -v ./...

echo "Terratest execution completed."
