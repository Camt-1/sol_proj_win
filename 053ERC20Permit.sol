// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./interface/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * EIP2612提出了ERC20Permit,扩展了ERC20标准,添加了一个permit函数,
 * 允许用户通过EIP-712签名修改授权,而不是通过msg.sender,有以下好处:
 * 1. 授权这步仅需用户在链下签名,减少一笔交易
 * 2. 签名后,用户可以委托第三方进行后续交易,不需要持有ETH;
 * 用户A可以将签名发送给拥有gas的第三方B,委托B来执行后续交易
 */
contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender, uint256 value,uint256 nonce,uint256 deadline)");
    
    //初始化EIP712的name以及ERC20的name和symbol
    constructor(
        string memory name,
        string memory symbol
    ) EIP712(name, "1") ERC20(name, symbol) {}

    //根据owner签名,将owner的ERC20代币余额授权给spender,数量为value
    /**
     * 要求:
     * - spender不能是零地址
     * - deadline必须是未来的时间戳
     * - v, r和 s必须是owner对EIP712格式的函数参数的有效keccak256签名
     * - 签名必须使用owner当前的nonce
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        //检查deadline
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        //拼接Hash
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
        bytes32 hash = _hashTypedDataV4(structHash);

        //从签名和消息计算signer,并验证签名
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        //授权
        _approve(owner, spender, value);
    }

    //返回owner当前的nonce,每次为permit()函数生成签名时,必须包括此值.
    //每次成功调用permit()函数都会将owner的nonce增加1,防止多次使用同一签名
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner];
    }

    //返回用于编码permit()函数的签名的域分隔符,如EIP712所定义
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    //消费nonce的函数,返回用户当前的nonce,并增加1
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner];
        _nonces[owner] += 1;
    }

    //铸造代币
    function mint(uint amount) external {
        _mint(msg.sender, amount);
    }
}