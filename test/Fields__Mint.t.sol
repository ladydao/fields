// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, stdStorage, StdStorage } from "forge-std/Test.sol";
import { IERC721Receiver } from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { DeployFields } from "../script/DeployFields.s.sol";
import { Fields } from "../src/Fields.sol";

contract MintTest is Test {
    using stdStorage for StdStorage;

    Fields public fields;
    DeployFields public deployer;

    string public nftCid1 = "bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4";
    string public nftCid2 = "bafkreidl6rlm5rqgn3b5b7b5tg4hfas7ansnk3e36agcncwijd5tupqwp4";

    function setUp() public {
        deployer = new DeployFields();
        fields = deployer.run();
    }

    function testMintRevertMintWithoutValue() public {
        vm.prank(address(1));
        vm.expectRevert(Fields.MintPriceNotPaid.selector);
        fields.safeMint(nftCid1);
    }

    function testMintRevertMintWithWrongValue() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        vm.expectRevert(Fields.MintPriceNotPaid.selector);
        fields.safeMint{ value: 0.15 ether }(nftCid1);
    }

    function testMintMintPricePaid() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        fields.safeMint{ value: 0.1 ether }(nftCid1);
    }

    function testMintPricePaidAssetNotForSale() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        vm.expectRevert(Fields.NotForSale.selector);
        fields.safeMint{ value: 0.1 ether }("asset_not_for_sale");
    }

    function testMintNewOwnerRegistered() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        uint256 mintedTokenId = fields.safeMint{ value: 0.1 ether }(nftCid1);

        // Check the owner using the public view function, not stdStorage
        address owner = fields.ownerOf(mintedTokenId);
        assertEq(owner, address(1), "Owner of the new token is incorrect");
    }

    function testMintIdIncreasesOnMinting() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        uint256 id1 = fields.safeMint{ value: 0.1 ether }(nftCid1);

        vm.prank(address(1));
        uint256 id2 = fields.safeMint{ value: 0.1 ether }(nftCid2);
        assertGt(id2, id1);
    }

    function testMintBalanceIncremented() public {
        vm.startPrank(address(1));
        vm.deal(address(1), 1 ether);

        // Check balance before minting
        assertEq(fields.balanceOf(address(1)), 0);

        // First mint
        fields.safeMint{ value: 0.1 ether }(nftCid1);
        assertEq(fields.balanceOf(address(1)), 1, "Balance after first mint is incorrect");

        // Second mint
        fields.safeMint{ value: 0.1 ether }(nftCid2);
        assertEq(fields.balanceOf(address(1)), 2, "Balance after second mint is incorrect");

        vm.stopPrank();
    }

    function testMintEmitEvent() public {
        ExpectEmit expectEmit = new ExpectEmit();
        Receiver receiver = new Receiver();

        vm.prank(address(receiver));
        vm.deal(address(receiver), 1 ether);
        fields.safeMint{ value: 0.1 ether }(nftCid1);

        expectEmit.mintEvent();
    }

    function testMintSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        vm.prank(address(receiver));
        vm.deal(address(receiver), 1 ether);
        fields.safeMint{ value: 0.1 ether }(nftCid1);
        uint256 receiverBalance =
            stdstore.target(address(fields)).sig(fields.balanceOf.selector).with_key(address(receiver)).find();

        uint256 balance = uint256(vm.load(address(fields), bytes32(receiverBalance)));
        assertEq(balance, 1);
    }

    function testMintRevertWhenUnsafeContractReceiver() public {
        address unsafeContract = address(0x123);
        vm.prank(unsafeContract);
        vm.deal(unsafeContract, 1 ether);
        vm.etch(unsafeContract, bytes("mock code"));

        vm.expectRevert();
        fields.safeMint{ value: 0.1 ether }(nftCid1);
    }
}

contract Receiver is IERC721Receiver {
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        bytes calldata /* data */
    )
        external
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}

contract ExpectEmit {
    event AddAsset(string asset);
    event Mint(address minter, string uri, uint256 id);

    function addAssetEvent() public {
        emit AddAsset("nft4");
    }

    function mintEvent() public {
        emit Mint(address(this), "nft4", 0);
    }
}
