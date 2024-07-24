-include .env

build:; forge build
snapshot:; forge snapshot
test: forge test -vvv
fork-test:; forge test -vvv --fork-url ${RPC_URL}