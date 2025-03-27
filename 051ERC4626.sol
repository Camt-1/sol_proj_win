// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC4626} from "./interface/IERC4626.sol";
import {ERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC4626 is ERC20, IERC4626 {
    ERC20 private immutable _asset;
    uint8 private immutable _decimals;

    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

// 存款/提款逻辑
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        //利用previewDeposit()计算获得的金库份额
        shares = previewDeposit(assets);

        //先transfer后mint,防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        //释放Deposit事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        //利用previewMint()计算需要存款的基础资产数额
        assets = previewMint(shares);

        //先transfer后mint,防止重入
        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        //释放Depostit事件
        emit Deposit(msg.sender, receiver, assets, shares);
    }
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        //利用previewWithdraw()计算将销毁的金库份额
        shares = previewWithdraw(assets);

        //如果调用者部署owner, 则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        //先销毁后transfer,防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        //释放Withdraw函数
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        //利用previewRedeem()计算能赎回的基础资产数额
        assets = previewRedeem(shares);

        //如果调用者不是owner,则检查并更新授权
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        //先销毁后transfer,防止重入
        _burn(owner, shares);
        _asset.transfer(receiver, assets);

        //释放Withdraw事件
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

// 会计逻辑
    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        //如果supply为0,那么1:1铸造金库份额
        //如果supply不为0,那么按比例铸造
        return supply == 0 ? assets : assets * supply / totalAssets();
    }
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();
        //如果supply为0,那么1:1赎回基础资产
        //如果supply不为0,那么按比例赎回
        return supply == 0 ? shares : shares * totalAssets() / supply;
    }
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    } 
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

// 存款/取款限制逻辑
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }
}