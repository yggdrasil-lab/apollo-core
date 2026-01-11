#!/bin/bash
set -e
# Usage: ./scripts/deploy.sh <STACK_NAME> [COMPOSE_FILES...]

# Requirement: Run ./setup_host.sh on the target node first.

./scripts/deploy.sh --skip-build "apollo-core" docker-compose.yml
