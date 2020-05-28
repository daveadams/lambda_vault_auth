#!/bin/bash -ex

# build/test.sh
# A semi-functional attempt to provide a test environment for this locally w/o needing to invoke a lambda.
# TODO: Finish this, or make something that runs a test lambda instead

# Capture VAULT_ADDR
OG_VAULT_ADDR=$VAULT_ADDR

# Start a container
# -e 'VAULT_LOCAL_CONFIG={"backend": {"file": {"path": "/vault/file"}}, "default_lease_ttl": "168h", "max_lease_ttl": "720h"}' \
docker run --rm --cap-add=IPC_LOCK \
  -d \
  --name=dev-vault \
  -p "8200:8200" \
  vault server -dev > /dev/null
cleanup() {
  VAULT_ADDR=$OG_VAULT_ADDR
  unset VAULT_AUTH_HEADER
  unset VAULT_AUTH_PROVIDER
  unset VAULT_AUTH_ROLE
  docker stop dev-vault &> /dev/null
  docker rm dev-vault &> /dev/null
}

trap cleanup EXIT

# export VAULT_AUTH_HEADER=localhost:8200
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_AUTH_PROVIDER=lambda
export VAULT_AUTH_ROLE=my-vault-role

# Check it is healthy
docker logs dev-vault

# Set up AWS auth ### FAILS!
# docker exec -e VAULT_ADDR="http://127.0.0.1:8200" dev-vault vault auth enable aws

# Run the ruby integration test against the vault
$(dirname "$0")/integration_test.rb
