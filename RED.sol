// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title The Dead Army Skeleton Klub
/// @author Burn0ut#8868 dev@notableart.xyz
/// @notice https://www.thedeadarmyskeletonklub.army/ https://twitter.com/The_DASK
contract RAW is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 7777;
    uint256 public constant MAX_PER_MINT = 3;
    address public constant w1 = 0x326D4FF1fd7Bd2a6741192Aba6176300D3f4cA71;
    address public constant w2 = 0x5AC3163754fc54FeA1541C7Fe1d707B5f7C4De84;
    address public constant w3 = 0x167ff7402F1B545A49a117Fd23a0360afE8761C1;


    uint256 public price = 0.01 ether;
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 1;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x1ec77273b979842b8d532d638dcdd667dc9d39a28d56a0eeac3d46e2505dd34f;

    constructor() ERC721A("Red Astro Wars", "RAW", 20) {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        } else {
            return
                string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmQPrJkT8cX72rasGdoMnWq713DwTGniMxxPadjVzgxmbG/", tokenId.toString()));
        }
    }

    /// Set number of maximum presale mints a wallet can have
    /// @param _newPresaleMaxPerWallet value to set
    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _newPresaleMaxPerWallet;
    }

    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "RAW: Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "RAW: You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "RAW: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "RAW: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");
        require(price * tokens == msg.value, "RAW: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "RAW: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "RAW: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");
        require(price * tokens == msg.value, "RAW: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "RAW: Minting would exceed max supply");
        require(tokens > 0, "RAW: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "RAW: Insufficent balance");
        _widthdraw(w3, ((balance * 45) / 1000));
        _widthdraw(w2, ((balance * 45) / 1000));
        _widthdraw(w1, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "RAW: Failed to widthdraw Ether");
    }

}