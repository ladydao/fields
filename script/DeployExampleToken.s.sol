// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";
import { ExampleToken } from "../src/ExampleToken.sol";

contract DeployExampleToken is Script {
    uint256 public defaultAnvilPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() external returns (ExampleToken) {
        if (block.chainid == 31_337) {
            deployerKey = defaultAnvilPrivateKey;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerKey);
        ExampleToken exampleToken = new ExampleToken();
        vm.stopBroadcast();
        return exampleToken;
    }
}
