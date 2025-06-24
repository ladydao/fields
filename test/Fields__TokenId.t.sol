// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { Fields } from "src/Fields.sol";

contract FieldsTokenIdTest is Test {
    Fields public fields;
    bytes32[] public assets;
    address public user = makeAddr("user");

    function setUp() public {
        assets.push(keccak256(abi.encodePacked("asset1")));
        assets.push(keccak256(abi.encodePacked("asset2")));
        fields = new Fields(assets);
        vm.deal(user, 1 ether);
    }

    function test_TokenIdIncrementsAfterBurn() public {
        // Mint token 0 as 'user'
        vm.startPrank(user);
        uint256 firstTokenId = fields.safeMint{ value: 0.1 ether }("asset1");
        assertEq(firstTokenId, 0, "First token ID should be 0");

        // Burn token 0 as 'user'
        fields.burn(firstTokenId);

        // Mint a second token as 'user'
        uint256 secondTokenId = fields.safeMint{ value: 0.1 ether }("asset2");
        vm.stopPrank();

        // The new token ID should be 1, not 0, because the counter increments
        // regardless of burning.
        assertEq(secondTokenId, 1, "Second token ID should be 1, not reused");
    }
}
