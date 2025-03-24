// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//中心化风险
/**
 * 中心化风险是指智能合约的所有权是中心化的,例如合约的owner由一个地址控制,它可以随意修改合约参数,
 * 甚至提取用户资金.中心化的项目存在单点风险,可以被恶意开发者或黑客利用,只需要获取具有控制权限地址的私钥之后,
 * 就可以通过rug-pull,无限铸币,或其他类型方法盗取资金
 */
/**
 * 链游项目Vulcan Forged因私钥泄露被盗1.4忆美元,
 * DeFi项目EasyFii因私钥泄露被盗5900万美元,
 * DeFi项目在钓鱼攻击中因私钥泄露被盗5500万美元
*/

//伪去中心化风险
/**
 * 使用多签钱包来管理智能合约,但几个多签人是一致行动人
 * Harmony公链的跨链桥由5个多签人控制,但离谱的是只需其中2个人签名就可以批准一笔交易
 */

/**
 * 最常见的例子: owner地址可以任意铸造代币的ERC20合约
 * 当项目内鬼或黑客获得owner的私钥后,可以无限铸币,造成投资人大量损失
 */
contract Centralization is ERC20, Ownable {
    constructor() ERC20("Centralization, "Cent) {
        address exposedAccount = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
        transferOwnership(exposedAccount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

/**
 * 减少中心化/伪中心化风险
 * 1. 使用多签钱包.为兼顾效率和去中心化,可以使用4/7或6/9多签
 * 2. 多签的持有人要多样化,分散在创始团队 投资人 社区领袖之间,并且不要互相授权签名
 * 3.使用时间锁控制合约,在黑客或项目内鬼修改合约的参数/盗取资产时,项目方和社区有一些时间来应对,
 */