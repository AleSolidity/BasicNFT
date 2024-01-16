// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyNft is ERC721, ERC721URIStorage, ERC721Pausable, AccessControl {
    uint256 private constant MINT_PRICE = 0.01 ether;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;
    address private immutable _mintWallet;
    address private immutable _taxWallet;

    constructor(
        address defaultAdmin, 
        address[] memory minters,
        address mintWallet,
        address taxWallet
        )
        ERC721("MyNft", "MNT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);

        for (uint256 i = 0; i < minters.length; i++) {
            _grantRole(MINTER_ROLE, minters[i]);
        }

        _mintWallet = mintWallet;
        _taxWallet = taxWallet;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function isEligibleToMint() 
        external         
        view
        returns (bool) 
    {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    mapping (string => uint8) existingURIs;

    function payToMint(
        address recipient,
        string memory metadataURI
    ) public payable returns (uint256) {
        require(!isContentOwned(metadataURI), 'NFT already minted!');
        require(msg.value >= MINT_PRICE, "Not enough ether to mint!");

        uint256 newItemId = _nextTokenId++;
        existingURIs[metadataURI] = 1;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);
        
        return newItemId;
    }

    function isContentOwned(string memory uri) 
    public
    view
    returns (bool) {
        return existingURIs[uri] == 1;
    }

    function count() public view returns (uint256) {
        return _nextTokenId;
    }
}