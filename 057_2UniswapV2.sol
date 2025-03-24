// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Lib.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;  
}

contract UniswapV2Flashloan is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH));
    }

    function flashloan(uint wethAmount) external {
        bytes memory data = abi.encode(WETH, wethAmount);

        pair.swap(0, wethAmount, address(this), data);
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == factory.getPair(token0, token1));

        (address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, uint256));

        require(tokenBorrow == WETH, "token borrow != WETH");

        uint fee = (amount1 * 3) / 997 + 1;
        uint amountToRepay = amount1 + fee;

        weth.transfer(address(pair), amountToRepay);
    }
}