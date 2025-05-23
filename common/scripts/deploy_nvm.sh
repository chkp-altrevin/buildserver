#!/bin/bash

# Define variables
export NVM_VERSION="0.40.1"
export NPM_NODE_VERSION="21"

# download installer
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash

# nvm install $NPM_NODE_VERSION
# nvm use $NPM_NODE_VERSION

# access nvm without logout
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
