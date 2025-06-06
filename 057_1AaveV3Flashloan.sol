// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./interface/Lib_Flashloan.sol";

    /**
     * - 在接收闪电借款资产后执行操作
     * - 确保合约能够归还债务 + 额外费用,例如,
     * 具有足够的资金来偿还,并已批准Pool提取总金额
     * = asset 闪电接借款资产的地址
     * - amount 闪电借款资产的费用
     * - initiator 发起闪电贷款的地址
     * - params 初始化闪电贷款时传递的字节编码参数
     * - 如果操作的执行成功则返回True,否则返回False
     */

interface IFlashLoanSimpleReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initator,
        bytes calldata params
    ) external returns (bool);
}

// AAVE V3 闪电贷合约
contract AaveV3Flashloan {
    address private constant AAVE_V3_POOL =
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ILendingPool public aave;

    constructor() {
        aave = ILendingPool(AAVE_V3_POOL);
    }

    //闪电贷函数
    function flashloan(uint256 wethAmount) external {
        aave.flashLoanSimple(address(this), WETH, wethAmount, "", 0);
    }

    //闪电贷回调函数,只能被 pool 合约调用
    function executeOpweation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata
    ) external returns (bool)
    {
        //确认调用的是 DAI/WETH pair 合约
        require(msg.sender == AAVE_V3_POOL, "not authorized");
        //确认闪电贷发起者是本合约
        require(initiator == address(this), "invalid initiator");

        //flashloan逻辑,这里省略

        //计算flashloan费用
        //fee = 5/1000 * amount
        uint fee = (amount * 5) / 10000 * 1;
        uint amountToRepay = amount + fee;

        //归还闪电贷
        IERC20(WETH).approve(AAVE_V3_POOL, amountToRepay);

        return true;
    }
}