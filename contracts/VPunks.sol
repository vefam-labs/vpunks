// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./energy.sol"; // VechainThor

contract VPunks is Context, Ownable, AccessControl, ERC721 {

    using SafeMath for uint256;

    // You can use this hash to verify the image file containing all the punks
    string public constant imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping (address => uint256) public userMintCount; // for Airdrop

    // for randomized
    uint256[10] private punks_index = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[] private punks_index_exists = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256 private constant punks_per_colum = 1000;
    //
    uint256 private _tokenIdCounter = 10000; // start mintWithRole
    uint256[11] private _priceList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    // VechainThor
    Energy constant energy = Energy(0x0000000000000000000000000000456E65726779);
    
    
    // ----------------------------------------------------------------------------
    constructor() ERC721("VPunks", "VPUNK") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }


    // ----------------------------------------------------------------------------
    // Write Contract
    // ----------------------------------------------------------------------------
    function mintNFT(uint256 numberOfNfts) external payable returns (bool[] memory results) {
        results = new bool[](numberOfNfts);
        
        uint256 sendAmount = msg.value;
        uint256 currPrice = getCurrentPrice();

        for (uint i = 0; i < numberOfNfts; i++) {
            if (sendAmount < currPrice) break;
            uint256 tokenId = getNextPunkIndex(i);
            if (_exists(tokenId)) continue;
            _safeMint(_msgSender(), tokenId);
            if (currPrice > 0) sendAmount = sendAmount.sub(currPrice);
            results[i] = true;
            userMintCount[_msgSender()] += 1;
        }
        if (sendAmount > 0) _msgSender().transfer(sendAmount);
    }
    //
    function mintWithRole(uint256 numberOfNfts, address to) external payable returns (bool[] memory results) {
        require(hasRole(MINTER_ROLE, _msgSender()), "E1");// E1 = ERC721: must have minter role
        // require(to != address(0), "ERC721: mint to the zero address"); // no need to check because ERC721 checked
    
        results = new bool[](numberOfNfts);
        uint256 sendAmount = msg.value;
        uint256 currPrice = _priceList[10];

        for (uint i = 0; i < numberOfNfts; i++) {
            if (sendAmount < currPrice) break;
            if (_exists(_tokenIdCounter) == false) {
                _safeMint(to, _tokenIdCounter);
                if (currPrice > 0) sendAmount = sendAmount.sub(currPrice);
                results[i] = true;
            }
            _tokenIdCounter += 1;
        }
        if (sendAmount > 0) _msgSender().transfer(sendAmount);
    }
    // ----------------------------------------------------------------------------
    // end Write Contract
    // ----------------------------------------------------------------------------



    // ----------------------------------------------------------------------------
    // internal|private Contract
    // ----------------------------------------------------------------------------
    function getNextPunkIndex(uint256 nonce) private returns (uint256) {
        uint256 length = punks_index_exists.length;
        if (length == 0) return 0;
        uint256 colum_index = uint256 (keccak256(abi.encodePacked(block.timestamp + nonce))) % length;
        uint256 p_index = punks_index[punks_index_exists[colum_index]] + punks_index_exists[colum_index] * punks_per_colum;
        punks_index[punks_index_exists[colum_index]] += 1;
        
        if (punks_index[punks_index_exists[colum_index]] >= punks_per_colum){
            if (colum_index < length - 1) {
                punks_index_exists[colum_index] = punks_index_exists[length - 1];
            }
            punks_index_exists.pop();
        }
        return p_index;
    }
    // ----------------------------------------------------------------------------
    // end internal|private Contract
    // ----------------------------------------------------------------------------



    // ----------------------------------------------------------------------------
    // Read Contract
    // ----------------------------------------------------------------------------
    function getPriceList() public view returns (uint256[11] memory) {
        return _priceList;
    }
    //
    function getMintRolePrice() public view returns (uint256) {
        return _priceList[10];
    }
    //
    function getCurrentPrice() public view returns (uint256) {
        uint256 mined = 0;
        uint256 phase = 0;
        for (uint i = 0; i < punks_index.length; i++) {
            mined += punks_index[i];
        }
        phase = mined/punks_per_colum;
        return _priceList[phase];
    }
    //
    function remainingNFT() public view returns (uint256 result) {
        for (uint i = 0; i < punks_index.length; i++) {
            result += punks_per_colum - punks_index[i];
        }
    }
    // ----------------------------------------------------------------------------
    // end Read Contract
    // ----------------------------------------------------------------------------


    
    // ----------------------------------------------------------------------------
    // onlyOwner Write Contract
    // ----------------------------------------------------------------------------
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
    //
    function updatePriceList(uint256[11] memory priceList_) public onlyOwner {
        _priceList = priceList_;
    }
    //
    function ownerWithdraw(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "E2");// E2 = ERC721: transfer to the zero address
        require(recipient != address(this), "E3");// E3 = ERC721: transfer to this contract address
        if (amount > address(this).balance) amount = address(this).balance;
        recipient.transfer(amount);
    }
    // VechainThor
    function ownerWithdrawVtho(address payable recipient, uint256 amount) external onlyOwner {
        // to save gas will not check E2, E3
        energy.transfer(recipient, amount);
    }
    /*
    function setTokenURI(uint tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
    function burnToken(uint tokenId) public onlyOwner {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "ERC721: sender must be an admin to grant");
        _burn(tokenId);
    }*/
    // ----------------------------------------------------------------------------
    // end onlyOwner Write Contract
    // ----------------------------------------------------------------------------



    // ----------------------------------------------------------------------------
    // onlyOwner Read Contract
    // ----------------------------------------------------------------------------
    function checkBalances() onlyOwner public view returns (uint256 balance) {
        balance = address(this).balance;
    }
    // ----------------------------------------------------------------------------
    // end onlyOwner Read Contract
    // ----------------------------------------------------------------------------
}
