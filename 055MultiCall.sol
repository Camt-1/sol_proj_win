// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Multicall {
    //Call结构体,包含目标合约target,是否允许调用失败allowFailure,和call data
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    //Result结构体,包含调用是否成功和return data
    struct Result {
        bool success;
        bytes returnData;
    }

    //将多个调用(指出不同合约/不同方法/不同参数)合并到一次调用
    //calls Call结构体组成的数组
    //returnData Result结构体组成的数组
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;

        //在循环中依次调用
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            //如果calli.allowFailure和result.success均为false,则revert
            if (!(calli.allowFailure || result.success)) {
                revert("Multicall: call failed");
            }
        }
    }
}