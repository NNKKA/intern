// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ToyTokenVestingContract is Ownable {

    /// @notice ToyToken Contract Address
    IERC20 public ToyToken;

    bool firstVesting;

    /// @notice Total Amount Of Token released
    uint256 public TokenWithdrawn;

    uint256 checkPoint;

     /// @notice Total period which token will be vested
    uint256 public TotalVestingPeriod;

    error VestEmpty();

    event ToyTokenReleased(uint amount);


    /**
    * @dev Sets the ToyToken Contract address
    * Vesting period starts immediately on contract
    */
    constructor(address _toyTokenAddress){
        ToyToken = IERC20(_toyTokenAddress);
        firstVesting = true;
        checkPoint = block.timestamp;
        TotalVestingPeriod = checkPoint + 90 days;
    }


    /**
     * @dev change the ToyToken Contract address).
     * Can only be called by the current owner.
     */
    function changeToyTokenAddress(address _toyTokenAddress) external onlyOwner returns(bool){
        ToyToken = IERC20(_toyTokenAddress);
        return true;
    }


     /**
     * @dev function to withdraw tokens.
     * On first call withdraws 10% of the totalSupply of ToyToken.
     * Can only be called by the current owner.
     */
    function withDrawTokens() external onlyOwner returns(bool){
        if(ToyToken.balanceOf(address(this)) == 0){
           revert VestEmpty();
        }
        uint amount = getTokenAllowedToWithdraw();
        ToyToken.approve(_msgSender(),amount);
        ToyToken.transfer(_msgSender(), amount);
        TokenWithdrawn += amount;
        emit ToyTokenReleased(amount);
        return true;
    }

     /**
     * @dev returns the token amount available for withdrawal.
     * Can only be called by the current owner.
     */
    function getAvailableTokenToWithdraw() external onlyOwner returns(uint amount){
        amount = getTokenAllowedToWithdraw();
    }


     /**
     * @dev calculate the token available for withdraw.
     */
    function getTokenAllowedToWithdraw() private returns(uint){
        uint ToyTokenSupply = ToyToken.totalSupply();
        uint amount;
        uint secPassed;
        if(firstVesting){
            amount = (ToyTokenSupply*10)/100;
        }

        if(!firstVesting){
            if(block.timestamp < TotalVestingPeriod){
                secPassed =  block.timestamp - checkPoint;
                uint ratePerSec = secPassed*1000/86400;
                amount = ratePerSec*10**18;
                checkPoint = block.timestamp;
            }

            if(block.timestamp >= TotalVestingPeriod){
                secPassed =  TotalVestingPeriod - checkPoint;
                uint ratePerSec = secPassed*1000/86400;
                amount = ratePerSec*10**18;
                checkPoint = block.timestamp;
            }
        }
        firstVesting = false;
        return amount;
    }
}