// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./031ERC20.sol";
import "./interface/IERC20.sol";

contract TokenLocker {
    event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
    event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);

    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable lockTime;
    uint256 public immutable startTime;

    constructor(
        IERC20 _token,
        address _beneficiary,
        uint256 _lockTime
    )
    {
        require(_lockTime > 0, "TokenLock: lock times should greater than 0");
        token = _token;
        beneficiary = _beneficiary;
        lockTime = _lockTime;
        startTime = block.timestamp;

        emit TokenLockStart(_beneficiary, address(_token), block.timestamp, _lockTime);
    }

    function release() public {
        require(block.timestamp >= startTime + lockTime, "TokenLock: current time is before release time");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "TokenLock: no tokens to release");

        token.transfer(beneficiary, amount);

        emit Release(msg.sender, address(token), block.timestamp, amount);
    }
}