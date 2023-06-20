// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console, stdStorage, StdStorage } from "forge-std/Test.sol";
import { IERC721Receiver } from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { DeployFields } from "../script/DeployFields.s.sol";
import { DeployExampleToken } from "../script/DeployExampleToken.s.sol";
import { Fields } from "../src/Fields.sol";
import { ExampleToken } from "../src/ExampleToken.sol";

contract WithdrawTest is Test {
    using stdStorage for StdStorage;

    Fields public fields;
    ExampleToken public exampleToken;
    DeployFields public fieldsDeployer;
    DeployExampleToken public deployExampleToken;

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        fieldsDeployer = new DeployFields();
        fields = fieldsDeployer.run();

        deployExampleToken = new DeployExampleToken();
        exampleToken = deployExampleToken.run();
        vm.prank(exampleToken.owner());
        exampleToken.transferOwnership(user1);
        vm.prank(user1);
        exampleToken.mint(user1, 1000 ether);
    }

    function testWithdrawalFailsAsNotOwner() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        fields.safeMint{ value: 0.1 ether }("bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4");
        fields.safeMint{ value: 0.1 ether }("bafkreibigzbpgnymvz4prm325ukcvm6nunkh767r7zewn7isaz6jnuopbi");
        vm.expectRevert("Ownable: caller is not the owner");
        fields.withdrawAll();
        vm.stopPrank();
    }

    function testWithdrawalWorksAsOwner() public {
        vm.startPrank(fields.owner());
        vm.deal(fields.owner(), 1 ether);
        fields.safeMint{ value: 0.1 ether }("bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4");
        fields.safeMint{ value: 0.1 ether }("bafkreibigzbpgnymvz4prm325ukcvm6nunkh767r7zewn7isaz6jnuopbi");

        fields.withdrawAll();
        vm.stopPrank();
    }

    function testWithdrawERC20WorksAsOwner() public {
        vm.prank(user1);
        exampleToken.transfer(address(fields), 1 ether);

        assertEq(exampleToken.balanceOf(address(fields)), 1 ether);

        vm.prank(fields.owner());
        fields.withdrawAllERC20(exampleToken);

        assertEq(exampleToken.balanceOf(address(fields)), 0);
    }

    function testFailWithdrawERC20NotAsOwner() public {
        vm.prank(user1);
        exampleToken.transfer(address(fields), 1 ether);

        assertEq(exampleToken.balanceOf(address(fields)), 1 ether);

        vm.prank(user2);
        fields.withdrawAllERC20(exampleToken);

        assertEq(exampleToken.balanceOf(address(fields)), 1 ether);
    }
}
