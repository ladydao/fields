# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Build: `forge build`
- Test: `forge test`
- Test single file: `forge test --match-path test/Fields__Mint.t.sol`
- Test single function: `forge test --match-test testMintRevertMintWithoutValue`
- Lint: `yarn lint`
- Format Solidity: `forge fmt`
- Clean: `yarn clean`

## Code Style Guidelines
- Solidity version: 0.8.19
- Imports: Organize imports by functionality/type
- Error handling: Use custom errors instead of require with strings
- Formatting: 
  - Line length: 120 characters
  - Bracket spacing: true
  - Tab width: 4 spaces
  - Quote style: double quotes
- Function order: external/public/internal/private
- Documentation: NatSpec format for all functions and contracts
- Naming: Use camelCase for variables/functions, PascalCase for contracts/interfaces
- State variables: Group by related functionality with clear comments