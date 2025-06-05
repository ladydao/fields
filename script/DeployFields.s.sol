// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Script } from "forge-std/Script.sol";
import { Fields } from "../src/Fields.sol";

contract DeployFields is Script {
    uint256 public defaultAnvilPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function run() external returns (Fields) {
        if (block.chainid == 31_337) {
            deployerKey = defaultAnvilPrivateKey;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }

        bytes32[] memory assets = new bytes32[](3);
        assets[0] = bytes32(0xc139ec3a54d28b4b1c040b5e9fd942f2c9ed9d5b18d607cbad706b3b5f8dd492);
        assets[1] = bytes32(0xfe39c7a53e126917d3c9f65bb3cb76045d74b81c7965621cf85d7f58f3b32c30);
        assets[2] = bytes32(0x11008326aead291f10f5b6f92a2a56d0f6c8e347ef87629528e57e362b207df8);

        vm.startBroadcast(deployerKey);
        Fields fields = new Fields(assets);
        vm.stopBroadcast();
        return fields;
    }
}
