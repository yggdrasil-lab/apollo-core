#!/bin/bash
set -e
source ./scripts/load_env.sh
export PLACEMENT_CONSTRAINT="node.role == manager"

# Ensure host is ready
if [ -f "./setup_host.sh" ]; then
    chmod +x ./setup_host.sh
    ./setup_host.sh
fi

./scripts/deploy.sh --skip-build "apollo-core-dev" docker-compose.yml
