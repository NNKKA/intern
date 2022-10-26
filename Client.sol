// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFT_Collection is ERC721Enumerable, Ownable, Pausable {
    /**
     *baseURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string baseURI;

    // max number of tokens
    uint256 public maxSupply;

    // token mint price
    uint256 public mintPrice;

    //  counters used to track the number of ids and issuing ERC721 ids
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    event changedPrice(uint256 oldPrice, uint256 newPrice);

    constructor(
        uint256 _maxSupply,
        uint256 _mintPrice,
        string memory _baseUri
    ) ERC721("CryptoToken", "CT") {
        baseURI = _baseUri;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
    }

    // mint allows a user to mint one NFT per transaction
    function mint() public payable whenNotPaused {
        require(msg.value >= mintPrice, "not enough ether to mint");
        require(totalSupply() < maxSupply, "maximum tokens minted");
        uint256 tokenId = tokenIdCounter.current();
        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender, tokenId);
        tokenIdCounter.increment();
    }

    // function to burn token, only owner or approved can burn the token
    function burn(uint256 tokenId) public virtual returns (bool) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
        return true;
    }

    /**
     * _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //function to change mint_Price
    function changeMintPrice(uint256 _price) public onlyOwner {
        emit changedPrice(mintPrice, _price);
        mintPrice = _price;
    }

    //function to pause minting
    function pause() external onlyOwner {
        _pause();
    }

    //function to unpause minting
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * withdraw sends all the ether in the contract
     * to the owner of the contract
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "failed to withdraw");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}