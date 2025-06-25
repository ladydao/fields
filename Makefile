# Makefile – local workflow for Fields
# -----------------------------------
# Prerequisites: Foundry installed (anvil, cast, forge)
#
# Targets
#   make anvil              – start local node (stores PID in .anvil.pid)
#   make deploy             – deploy Fields via script/DeployFields.s.sol
#   make owner              – cast call owner()
#   make collection-size    – cast call collectionSize()
#   make call fn="sig()" args="..." – arbitrary cast call helper
#   make stop               – stop anvil

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
RPC_URL          ?= http://localhost:8545
ANVIL_PORT       ?= 8545
ANVIL_CHAIN_ID   ?= 31337
ANVIL_PID_FILE   := .anvil.pid
CONTRACT_FILE    := .contract-address
PRIVATE_KEY      ?= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Dummy keys so foundry.toml variable interpolation does not fail
export API_KEY_ARBISCAN        := dummy
export API_KEY_SNOWTRACE       := dummy
export API_KEY_BSCSCAN         := dummy
export API_KEY_GNOSISSCAN      := dummy
export API_KEY_ETHERSCAN       := dummy
export API_KEY_OPTIMISTIC_ETHERSCAN := dummy
export API_KEY_POLYGONSCAN     := dummy

# ---------------------------------------------------------------------------
# Anvil helpers
# ---------------------------------------------------------------------------
.PHONY: anvil
anvil:
	@if [ -f $(ANVIL_PID_FILE) ] && kill -0 $$(cat $(ANVIL_PID_FILE)) 2>/dev/null; then \
		echo "anvil already running (PID $$(cat $(ANVIL_PID_FILE)))"; \
	else \
		anvil -p $(ANVIL_PORT) --chain-id $(ANVIL_CHAIN_ID) --silent & \
		echo $$! > $(ANVIL_PID_FILE); \
		sleep 1; \
		echo "anvil started (PID $$(cat $(ANVIL_PID_FILE)))"; \
	fi

.PHONY: stop
stop:
	@if [ -f $(ANVIL_PID_FILE) ]; then \
		echo "Stopping anvil (PID $$(cat $(ANVIL_PID_FILE)))"; \
		kill $$(cat $(ANVIL_PID_FILE)) || true; \
		rm -f $(ANVIL_PID_FILE); \
	else \
		echo "No anvil pidfile found"; \
	fi

# ---------------------------------------------------------------------------
# Deployment
# ---------------------------------------------------------------------------
.PHONY: deploy
deploy: $(CONTRACT_FILE)
	@echo "Fields deployed at $$(cat $(CONTRACT_FILE))"

$(CONTRACT_FILE): anvil script/DeployFields.s.sol
	@echo "Deploying Fields…";
	@forge script script/DeployFields.s.sol \
	  --broadcast \
	  --private-key $(PRIVATE_KEY) \
	  --rpc-url $(RPC_URL) -vvvv;
	@# Try extracting address from broadcast json (preferred)
	@RUN_JSON=$$(ls -t broadcast/DeployFields.s.sol/$(ANVIL_CHAIN_ID)/*run*.json | head -n1); \
	if command -v jq >/dev/null 2>&1 && [ -f "$$RUN_JSON" ]; then \
	  jq -r '.transactions[-1].contractAddress' "$$RUN_JSON" > $(CONTRACT_FILE); \
	else \
	  echo "Warning: jq not found; falling back to grep"; \
	  grep -Eo "0x[a-fA-F0-9]{40}" $$RUN_JSON | head -1 > $(CONTRACT_FILE); \
	fi
	@echo "Saved contract address to $(CONTRACT_FILE)"

# ---------------------------------------------------------------------------
# Cast helpers
# ---------------------------------------------------------------------------
ADDR := $(shell [ -f $(CONTRACT_FILE) ] && cat $(CONTRACT_FILE))

.PHONY: owner
owner:
	@if [ -z "$(ADDR)" ]; then echo "Run 'make deploy' first"; exit 1; fi
	@cast call $(ADDR) "owner()(address)" --rpc-url $(RPC_URL)

.PHONY: collection-size
collection-size:
	@if [ -z "$(ADDR)" ]; then echo "Run 'make deploy' first"; exit 1; fi
	@cast call $(ADDR) "collectionSize()(uint256)" --rpc-url $(RPC_URL)

.PHONY: call
call:
	@if [ -z "$(ADDR)" ]; then echo "Run 'make deploy' first"; exit 1; fi
	@if [ -z "$(fn)" ]; then echo "Usage: make call fn='signature' [args='...']"; exit 1; fi
	@cast call $(ADDR) "$(fn)" $(args) --rpc-url $(RPC_URL)

