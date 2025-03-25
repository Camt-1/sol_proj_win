// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Bank {
    mapping(address => uint256) public balanceOf; //余额mapping

    //存入ether,并更新余额
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    //提取msg.sender的全部ether
    function withdraw() external {
        //获取余额
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "insufficient balance");
        //转账ether!!!可能激活恶意合约的fallback/receive函数,有重入风险!
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
        //更新余额
        balanceOf[msg.sender] = 0;
    }

    //获取银行合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    Bank public bank; //Bank合约地址

    //初始化Bank合约地址
    constructor(Bank _bank) {
        bank = _bank;
    }

    //回调函数,用于重入攻击Bank合约,反复的调用目标的withdraw函数
    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw();
        }
    }

    //攻击函数,调用时msg.sender设为1 ether
    function attack() external payable {
        require(msg.sender == 1 ether, "Require 1 Ether to attack");
        bank.deposit{value: 1 ether}();
    }

    //获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

//利用 检查-影响-交互模式(check-effect-interaction)防止重入攻击
contract GoodBank {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "insufficient balance");
        //检查-效果-交互模式(check-effect-interaction): 先更新余额变化,再发送ETH
        //重入攻击的时候,balanceOf[msg.sender]已经被更新为0了,不能通过上面的检查
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

//利用重入锁防止重入攻击
contract ProtectedBank {
    mapping(address => uint256) public balanceOf;
    uint256 private _status;

    //重入锁
    modifier nonReentract() {
        //在第一次调用nonReentrant时,_status将是0
        require(_status == 0, "ReentrancyGuard: reentrant call");
        //在此之后对nonReentrant的任何调用都将失败
        _status = 1;
        _;
        //调用结束,将_status恢复为0
        _status = 0;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    //用重入锁保护有漏洞的函数
    function withdraw() external nonReentract {
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "insufficient balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");

        balanceOf[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}