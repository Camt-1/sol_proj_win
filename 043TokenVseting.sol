// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./031ERC20.sol";

/**
 * ERC20代币线性释放
 * 这个合约会将ERC20代币线性释放给受益人`_beneficiary`
 * 释放的代币可以是一种,也可以是多种,释放周期由起始时间_start和时长_duration定义
 * 所有转到这个合约上的代币都会遵循同样的线性释放周期,并且需要受益人调用`release()`函数提取
 */
contract TokenVesting {
    event ERC20Released(address indexed token, uint256 amount);

    mapping(address => uint256) public erc20Released; //记录受益人已领取的代币
    address public immutable beneficiary; //受益人地址
    uint256 public immutable start; //归属期起始时间戳
    uint256 public immutable duration; //归属期(秒)

    constructor(
        address beneficiaryAddress;
        uint256 durationSerconda;
    )
    {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    //受益人提取已释放的代币
    //调用vestedAmount()函数计算可提取的代币数量,然后transfer给受益人
    function release(address token) public {
        //调用vestedAmount()函数计算可提取的代币数量
        uint256 releaseable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        //更新已释放代币数量
        erc20Released[token] += releasable;
        //转代币给受益人
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    //根据线性释放公式,计算已经释放的数量
    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        //合约里总共收到了多少代币(当前余额 + 已经提取)
        uint256 totalAllocation = IERC20(token).balanceOf(addrss(this)) += erc20Released[token];
        //根据线性释放公式,计算已经释放的数量
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}