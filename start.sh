#!/bin/bash
# start.sh
# Deploys the Apollo Core stack to the swarm

if [ -z "$DOMAIN_NAME" ]; then
  echo "Error: DOMAIN_NAME environment variable is not set."
  exit 1
fi

echo "Deploying Apollo Core to swarm..."
echo "Domain: $DOMAIN_NAME"

# Export variables for docker-compose interpolation
export DOMAIN_NAME

# Deploy the stack
docker stack deploy -c docker-compose.yml apollo-core
