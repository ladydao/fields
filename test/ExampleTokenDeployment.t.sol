// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, stdStorage, StdStorage } from "forge-std/Test.sol";
import { DeployExampleToken } from "../script/DeployExampleToken.s.sol";
import { ExampleToken } from "../src/ExampleToken.sol";

contract ExampleTokenDeployment is Test {
    using stdStorage for StdStorage;

    ExampleToken public exampleToken;
    DeployExampleToken public deployer;

    string public tokenName = "ExampleToken";
    string public tokenSymbol = "ETK";
    address public user = makeAddr("user1");

    function setUp() public {
        deployer = new DeployExampleToken();
        exampleToken = deployer.run();
    }

    function testETKNameAndSymbol() public view {
        assert(keccak256(abi.encodePacked(exampleToken.name())) == keccak256(abi.encodePacked((tokenName))));
        assert(keccak256(abi.encodePacked(exampleToken.symbol())) == keccak256(abi.encodePacked((tokenSymbol))));
    }

    function testETKMintTokens() public {
        uint256 initBalance = exampleToken.balanceOf(user);
        vm.prank(exampleToken.owner());
        exampleToken.mint(user, 1000 ether);
        uint256 finalBalance = exampleToken.balanceOf(user);

        assertGt(finalBalance, initBalance);
        assertEq(finalBalance, 1000 ether);
    }
}
