// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployFields} from "../script/DeployFields.s.sol";
import {Fields} from "../src/Fields.sol";

contract PauseTest is Test {
    using stdStorage for StdStorage;

    Fields public fields;
    DeployFields public deployer;

    function setUp() public {
        deployer = new DeployFields();
        fields = deployer.run();
    }

    function testPauseOnlyOwnerCanToggleStatus() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        vm.expectRevert("Ownable: caller is not the owner");
        fields.toggleMintStatus();

        uint256 mintActiveSelector = stdstore.target(address(fields)).sig(fields.mintActive.selector).find();
        uint256 mintStatusInit = uint256(vm.load(address(fields), bytes32(mintActiveSelector)));
        assertEq(mintStatusInit, 1);

        vm.prank(address(fields.owner()));
        fields.toggleMintStatus();

        uint256 mintStatusAfter = uint256(vm.load(address(fields), bytes32(mintActiveSelector)));
        assertEq(mintStatusAfter, 0);
    }

    function testPauseToggleMintStatus() public {
        uint256 mintActiveSelector = stdstore.target(address(fields)).sig(fields.mintActive.selector).find();
        uint256 mintStatusInit = uint256(vm.load(address(fields), bytes32(mintActiveSelector)));
        assertEq(mintStatusInit, 1);

        vm.prank(address(fields.owner()));
        fields.toggleMintStatus();
        uint256 mintStatusAfter = uint256(vm.load(address(fields), bytes32(mintActiveSelector)));
        assertEq(mintStatusAfter, 0);
    }

    function testPauseNotAbleToMint() public {
        vm.prank(address(fields.owner()));
        fields.toggleMintStatus();
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        vm.expectRevert(Fields.MintNotActive.selector);
        fields.safeMint{value: 0.1 ether}("bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4");
    }

    function testPauseNotAbleToAddAssets() public {
        vm.startPrank(address(fields.owner()));
        vm.deal(address(fields.owner()), 1 ether);

        fields.toggleMintStatus();

        bytes32[] memory assets = new bytes32[](1);
        assets[0] = bytes32("nft4");
        vm.expectRevert(Fields.MintNotActive.selector);
        fields.addAssets(assets);
        vm.stopPrank();
    }
}
