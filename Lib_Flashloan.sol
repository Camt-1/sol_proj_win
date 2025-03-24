// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender,uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Ount,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    
    struct Poolkey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns (PoolKey memory)
    {
        if (tokenA > tokenB) (tokenA, tokenB) = (toeknB, tokenA)
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    function computeAddress(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.code(key.token0, key.token1, key, fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

interface IUinswapV3Pool {
    function flash(
        address recipient,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface ILendingPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);
}