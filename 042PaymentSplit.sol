// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract PaymentSplit{
    event PayeeAdded(address account, uint256 shares); //增加受益人事件
    event PaymentRelased(address to, uint256 amount); //受益人提款事件
    event PaymentReceived(address from, uint256 amount); //合约收款事件

    uint256 public totalShares; //总份额
    uint256 public totalReleased; //总支付

    mapping(address => uint256) public shares; //每个受益人的份额
    mapping(address => uint256) public released; //支付给每个受益人的金额
    address[] public payees; //受益人数组

    constructor(address[] memory _payees,uint256[] memory _shares) payable {
        //检查_payees和_shares数组长度相同,且不为0
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        //调用_addPayee,更新受益人地址payees 受益人份额shares 和 总份额totalShares
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function release(address payable _account) public virtual {
        //account必须是有效受益人
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        //计算account应得的eth
        uint256 payment = releasable(_account);
        //应得的eth不为0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        //更新总支付totalRelease和支付给每个受益人的金额released
        totalReleased += payment;
        released[_account] += payment;
        //转账
        _account.transfer(payment);
        emit PaymentRelased(_account, payment);
    }

    //计算一个账户能够领取的eth,调用pendingPayment()函数
    function releasable(address _account) public view returns (uint256) {
        //计算分账合约总收入totalReceived
        uint256 totalReceived = address(this).balance + totalReleased;
        //调用_pendingPayment计算account应得的ETH
        return pendingPayment(_account, totalReceived, released[_account]);
    }

    //根据受益人地址account,分账合约总收入totalReceived和该地址已领取的钱_alreadyReleased,
    //计算该受益人现在应分得的eth
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        //account应得的eth = 总应得eth - 已领到的eth
        return (_totalReceived * shares[_account] / totalShares - _alreadyReleased);
    }

    //新增受益人_account以及对应的份额_accountShares
    //只能在构造器中使用,不能修改
    function _addPayee(address _account, uint256 _accountShares) private {
        //检查_account不为0地址
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        //检查_accountShare不为0
        require(_accountShares > 0, "PaymentSpliter: shares are 0");
        //检查_account不重复
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        //更新payees, shares和totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        //释放新增受益人事件
        emit PayeeAdded(_account, _accountShares);
    }
}