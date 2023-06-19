// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * ███████╗██╗███████╗██╗░░░░░██████╗░░██████╗
 * ██╔════╝██║██╔════╝██║░░░░░██╔══██╗██╔════╝
 * █████╗░░██║█████╗░░██║░░░░░██║░░██║╚█████╗░
 * ██╔══╝░░██║██╔══╝░░██║░░░░░██║░░██║░╚═══██╗
 * ██║░░░░░██║███████╗███████╗██████╔╝██████╔╝
 * ╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═════╝░╚═════╝░
 *
 * @title Fields
 * @author dao.nomad@proton.me
 * @notice This contract manages a collection of unique digital assets on the Ethereum blockchain.
 * @notice It deploys with initial collection.
 * @notice It allows the owner to add more assets later but only up to the supply limit.
 * @dev Inherits from ERC721, ERC721Enumerable, ERC721URIStorage, and Ownable.
 */

contract Fields is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    ///////////////
    // Errors    //
    ///////////////
    error MintPriceNotPaid();
    error NotForSale();
    error DuplicateAsset();
    error SupplyCapReached();
    error MintNotActive();

    ////////////////////////
    // State Variables    //
    ////////////////////////
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public collectionSize;
    bool public mintActive = true;
    mapping(bytes32 assetHash => bool forSaleStatus) public isForSale;

    ///////////////
    // Events    //
    ///////////////
    /**
     * @notice Emitted when a new token is minted
     * @param minter Address of the account that minted the token
     * @param uri The URI of the token that was minted
     * @param id The ID of the token that was minted
     */
    event Mint(address minter, string uri, uint256 id);

    /**
     * @notice Emitted when a new asset is added
     * @param asset The hash of the asset that was added
     */
    event AddAsset(bytes32 asset);

    ////////////////////
    // Constructor    //
    ////////////////////
    /**
     * @notice Creates a new instance of the Fields contract
     * @param assets An array of assets available for sale at the time of contract creation
     */
    constructor(bytes32[] memory assets) ERC721("Fields", "FLD") {
        _flagForSale(assets);
    }

    ////////////////////////
    // External Functions //
    ////////////////////////
    /**
     * @notice Adds multiple new assets to the collection
     * @dev Only the owner can add new assets
     * @param assets An array of assets to be added to the collection
     * @return true if the assets are successfully added
     */
    function addAssets(bytes32[] memory assets) external onlyOwner returns (bool) {
        if (!mintActive) {
            revert MintNotActive();
        }
        if (assets.length + collectionSize > MAX_SUPPLY) {
            revert SupplyCapReached();
        }
        _flagForSale(assets);
        return true;
    }

    /**
     * @notice Mints a new token
     * @dev The sender must pay the minting price and the asset must be available for sale
     * @param uri The URI of the asset to be minted (ipfs CID)
     * @return The ID of the newly minted token
     */
    function safeMint(string memory uri) external payable returns (uint256) {
        if (!mintActive) {
            revert MintNotActive();
        }

        if (msg.value != MINT_PRICE) {
            revert MintPriceNotPaid();
        }

        bytes32 uriHash = keccak256(abi.encodePacked(uri));
        if (!isForSale[uriHash]) {
            revert NotForSale();
        }
        isForSale[uriHash] = false;

        uint256 current = totalSupply();
        uint256 newTokenID = ++current;

        _safeMint(msg.sender, newTokenID);
        _setTokenURI(newTokenID, uri);

        emit Mint(msg.sender, uri, newTokenID);
        return newTokenID;
    }

    /**
     * @notice Toggles the mint status
     * @dev Only the owner can pause the contract
     */
    function toggleMintStatus() external onlyOwner {
        mintActive = !mintActive;
    }

    /**
     * @notice Withdraws all Ether held by the contract
     * @dev Only the owner can withdraw the Ether
     * @dev Withdrawal address is hardcoded to be the owner address
     */
    function withdrawAll() public onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice Withdraws all of a specific ERC20 token held by the contract
     * @dev Only the owner can withdraw the tokens
     * @param _erc20Token The ERC20 token to be withdrawn
     */
    function withdrawAllERC20(IERC20 _erc20Token) external onlyOwner {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////
    /**
     * @notice Flags multiple assets as available for sale
     * @param assets An array of assets to be flagged for sale
     */
    function _flagForSale(bytes32[] memory assets) internal {
        uint256 len = assets.length;

        for (uint256 i = 0; i < len;) {
            if (isForSale[assets[i]]) {
                revert DuplicateAsset();
            }
            isForSale[assets[i]] = true;
            collectionSize = collectionSize + 1;
            emit AddAsset(assets[i]);
            ++i;
        }
    }

    ////////////////////////
    // required overrides //
    ////////////////////////
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
