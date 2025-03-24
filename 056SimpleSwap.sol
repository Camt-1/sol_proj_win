// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ERC20 {
    //代币合约
    IERC20 public token0;
    IERC20 public token1;
    
    //代币存储量
    uint public reserve0;
    uint public reserve1;

    //事件
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint amountIn,
        address tokenIn,
        uint amountOut,
        address tokenOut
    );

    //初始化代币地址
    constructor(
        IERC20 _token0,
        IERC20 _token1
    ) ERC20("SimpleSwap", 55) {
        token0 = _token0;
        token1 = _token1;
    }

    //取两个数最小值
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    //计算平方根
    function sqrt(uint y) internal pure returns (uint z) {
        if(y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    //添加流动性,转进代币,铸造LP
    //如果首次添加, 铸造的LP数量 = sqrt(amount0 * amount1)
    //如果非首次, 铸造的LP数量 = min(amount0/reserve0, amount1/reserve1) * totalSupply_LP
    //amount0Desired 添加的token0数量
    //amount1Desired 添加的token1数量
    function addLiquidity(
        uint amount0Desired,
        uint amount1Desired,
    ) public returns (uint liquidity)
    {
        //添加的流动性转入Swap合约,需事先给Swap合约授权
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);

        //计算添加的流动性
        uint _totalSupply = totalSupply();
        if(_totalSupply == 0) {
            //如果第一次添加流动性,铸造L = sqrt(x * y)单位的LP代币
            liquidity = sqrt(amount0Desired * amount1Desired);
        } else {
            //如果不是第一次添加流动性,按添加代币的数量比例铸造LP,取两个代币更小的那个比例
            liquidity = min(amount0Desired * _totalSupply / reserve0,
                amoount1Desired * _totalSupply / reserve1);
        }

        //检查铸造的LP数量
        require(liquidity > 0, "insufficent_liquidity_minted");

        //更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        //给流动性提供者铸造LP代币,代表他们提供的流动性
        _mint(msg.sender, liquidity);

        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    //移除流动性,销毁LP,转出代币
    //转出数量 = (liquidity / totalSupply_LP) * reserve
    function removeLiquidity(uint liquidity)
        external
        returns (uint amount0,int amount1) 
    {
        //获取余额
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        //按LP的比例计算要转出的代币数量
        uint _totalSupply = totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        //检查代币数量
        require(amount0 > 0 && amount1 > 0, "insufficient_liquidity_burned");
        //销毁LP
        _burn(msg.sender, liquidity);
        //转出代币
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        //更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    //给定一个资产的数量和代币对的储备,计算交换另一个代币的数量
    //由于乘积恒定
    //交换前: k = x * y
    //交换后: k = (x + delta_x) * (y + delta_y)
    //可得delta_y = (-delta_x * y) / (x + delta_x)
    //正/负号代表转入/转出
        function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut,
    ) public pure returns (uint amountOut)
    {
        require(amountIn > 0, "insufficinet_amount");
        require(reserveIn > 0 && reserveOut > 0, "insufficient_amount");
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);  
    }

    //Swap代币
    //amountIn 用于交换的代币数量
    //tokenIn 用于交换的代币合约地址
    //amountOutMin 交换出另一种代币的最低数量
    function swap(
        uint amountIn,
        IERC20 tokenIn,
        uint amountOutMin
    ) external returns (amountOut, IERC20 tokenOut)
    {
        require(amountIn > 0, "insufficient_output_amount");
        require(tokenIn == token0 || tokenIn == token1, "invalid_token");

        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if(tokenIn == token0) {
            //如果是token0交换token1
            tokenOut = token1;
            //计算能交换出的token1数量      
            amountOut = getAmountOut(amountIn, balance0, balance1)
            require(amountOut > amountOutMin, "insufficient_output_amount");
            //进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        } else {
            //如果是token1交换token0
            tokenOut = token0;
            //计算能交换从的token0数量
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, "insufficient_output_amount");
            //进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        //更新储备量
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}