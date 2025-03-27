// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC4626 is IERC20, IERC20Metadata {
    //存款时触发
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    //取款时触发
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

// 存款/提款逻辑
    //返回金库的基础资产代币地址(用于存款,取款)
    function asset() external view returns (address assetTokenAddress);
    //存款函数: 用户向金库存入assets单位的基础资产,然后合约铸造shares单位的金库额度给receiver地址
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    //铸造函数: 用户存入assets单位的基础资产,然后合约给receiver地址铸造share数量的金库额度
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    //赎回函数: owner地址销毁shares数量的金库额度,然后合约将assets单位的基础资产发给receiver呆滞
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

// 会计逻辑
    //返回金库中管理的基础资产代币总额
    function totalAssets() external view returns (uint256 totalManagedAssets);
    //返回利用一定数额基础资产可以换取的金库额度
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    //返回利用一定数额金库额度可以换取的基础资产
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    //用于链上和链下用户在当前链上环境模拟存款一定数额的基础资产能够获得金库额度
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    //用于链上和链下用户在当前链上环境模拟铸造shares份额的金库额度需要存款的基础资产数量
    function previewMint(uint256 shares) external view returns (uint256 asset);
    //用于链上和链下用户在当前链上环境模拟提款assets数额的基础资产需要赎回的金库份额
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    //用于链上和链下用户在当前链上环境模拟销毁shares数额的金库额度能够赎回的基础资产数量
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

// 存款/取款限额逻辑
    //返回某个用户地址单次存款可存的最大基础资产数额
    function macDeposit(address receiver) external view returns (uint256 macAssets);
    //返回某个用户地址单次铸造可以铸造的最大金库额度
    function maxMint(address receiver) external view returns (uint256 macShares);
    //返回某个用户地址单词取款可以提取的最大基础资产额度
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);
    //返回某个用户地址单词赎回可以销毁的最大金库额度
    function maxRedeem(address owner) external view returns (uint256 maxShares);
}