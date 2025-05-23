// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 private DOMAIN_SEPARATOR;
    uint256 number;
    address owner;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH, //type hash
            keccak256(bytes("EIP712Storage")), //name
            keccak256(bytes("1")), //version
            block.chainid, //chain id
            address(this) //contract address
        ));
        owner = msg.sender;    
    }

    //Store value in variable
    function permitStore(uint256 _num, bytes memory _signature) public {
        //检查签名长度,65是标准r,s,v签名的长度
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            //读取长度数据后的32 bytes
            r := mload(add(_signature, 0x20))
            //读取之后的32 bytes
            s := mload(add(_signature, 0x40))
            //读取最后一个byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        //获取签名消息hash
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        ));
        address signer = digest.recover(v, r, s); //恢复签名者
        require(signer == owner, "EIP712Storage: invalid signature"); //检查签名
        //修改状态变量
        number = _num;
    }

    //Return value
    function retrieve() public view returns (uint256){
        return number;
    }
}
