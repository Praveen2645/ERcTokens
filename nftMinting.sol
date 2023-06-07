pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFTContract is ERC721 {
    uint256 private tokenIdCounter;
    mapping(uint256 => string) private tokenURIs;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to, string memory tokenURI) external returns (uint256) {
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter++;

        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        tokenURIs[tokenId] = tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return tokenURIs[tokenId];
    }
}
