// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, stdStorage, StdStorage } from "forge-std/Test.sol";
import { DeployFields } from "../script/DeployFields.s.sol";
import { Fields } from "../src/Fields.sol";

contract DeploymentTest is Test {
    using stdStorage for StdStorage;

    string public constant NFT_NAME = "Fields";
    string public constant NFT_SYMBOL = "FLD";

    Fields public fields;
    DeployFields public deployer;

    function setUp() public {
        deployer = new DeployFields();
        fields = deployer.run();
    }

    function testDeployInitializedCorrectly() public {
        assert(keccak256(abi.encodePacked(fields.name())) == keccak256(abi.encodePacked((NFT_NAME))));
        assert(keccak256(abi.encodePacked(fields.symbol())) == keccak256(abi.encodePacked((NFT_SYMBOL))));
        uint256 collectionSizeSelector = stdstore.target(address(fields)).sig(fields.collectionSize.selector).find();
        uint256 initCollectionSize = uint256(vm.load(address(fields), bytes32(collectionSizeSelector)));
        assertEq(initCollectionSize, 3);
    }

    function testDeployCollectionIsForSale() public {
        bytes32 uriHash1 =
            bytes32(keccak256(abi.encodePacked("bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4")));
        bytes32 uriHash2 =
            bytes32(keccak256(abi.encodePacked("bafkreidl6rlm5rqgn3b5b7b5tg4hfas7ansnk3e36agcncwijd5tupqwp4")));
        bytes32 uriHash3 =
            bytes32(keccak256(abi.encodePacked("bafkreibigzbpgnymvz4prm325ukcvm6nunkh767r7zewn7isaz6jnuopbi")));

        uint256 isForSaleSelector1 =
            stdstore.target(address(fields)).sig(fields.isForSale.selector).with_key(uriHash1).find();
        uint256 isForSaleSelector2 =
            stdstore.target(address(fields)).sig(fields.isForSale.selector).with_key(uriHash2).find();
        uint256 isForSaleSelector3 =
            stdstore.target(address(fields)).sig(fields.isForSale.selector).with_key(uriHash3).find();

        uint256 isForSale1 = uint256(vm.load(address(fields), bytes32(isForSaleSelector1)));
        assertEq(isForSale1, 1);
        uint256 isForSale2 = uint256(vm.load(address(fields), bytes32(isForSaleSelector2)));
        assertEq(isForSale2, 1);
        uint256 isForSale3 = uint256(vm.load(address(fields), bytes32(isForSaleSelector3)));
        assertEq(isForSale3, 1);
    }

    function testDeployCorrectBaseURI() public {
        vm.prank(address(1));
        vm.deal(address(1), 1 ether);
        uint256 mintedTokenId =
            fields.safeMint{ value: 0.1 ether }("bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4");

        // The _baseURI is "ipfs://", so the tokenURI should be "ipfs://<CID>"
        // We check against the token ID that was actually minted (which is 0)
        string memory expectedTokenUri = "ipfs://bafkreidcapki3wfwy356um7wvwiud4cpnrucnuumtlw6g3fjx6eswynlx4";
        assertEq(fields.tokenURI(mintedTokenId), expectedTokenUri, "Token URI is incorrect");
    }
}
