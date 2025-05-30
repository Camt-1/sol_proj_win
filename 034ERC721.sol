// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./interface/IERC165.sol";
import "./interface/IERC721.sol";
import "./interface/IERC721Receiver.sol";
import "./interface/IERC721Metadata.sol";
import "./interface/String.sol";

contract ERC721 is IERC721,IERC721Metadata {
    using Strings for uint256;
    
    string public override name; //token名称
    string public override symbol; //token代号

    //tokenId到owner的持有人映射
    mapping(uint => address) private _owners;
    //address到持仓数量的持仓量映射
    mapping(address => uint) private _balances;
    //tokenId到授权地址的授权映射
    mapping(uint => address) private _tokenApprovals;
    //owner到operator的批量授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //错误 无效的接收者
    error ERC721InvalidReceiver(address receiver);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    //实现IERC165接口supportsInterface
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    //实现IERC721的balanceOf,利用_balances变量查询owner地址的balance
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0), "owner is a null address");
        return _balances[owner];
    }

    //实现IERC721的ownerOf,利用_owners变量查询tokenId的owner地址
    function ownerOf(uint tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }

    //实现IERC721的isApprovedForAll,利用_operatorApprovals变量查询owner地址是否将锁持有有的NFT批量授权给了operator地址
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    //实现IERC721的setApprovalForAll,将持有代币全部授权给operator地址,调用_setApprovalForAll
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //实现IERC721的getApproved,利用_tolenApprovals变量查询tokenId的授权地址
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    //授权函数.通过调整_tokenApprovals来,授权to地址操作tokenId,同时释放Approval事件
    function _approval(
        address owner,
        address to,
        uint tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    //实现IERC721的approve,将tokenId授权给to地址
    //条件:to不是owner,且msg.sender是owner或授权地址.调用_approve函数
    function approve(address to, uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all"
        );
        _approval(owner, to, tokenId);
    }

    //查询spender地址是否可以使用tokenId(需要时owner或授权地址)
    function _isApprovedOrOwner(
        address owner,
        address spender,
        uint tokenId
    ) private view returns (bool) {
        return spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender];
    }

    /**
     * 转账函数.通过调整_balances和owner变量将tokenId从from转账给to,同时释放Transfer事件
     * 条件:
     * 1. tokenId被from持有
     * 2. to不是0地址
     */
    function _transfer(
        address owner,
        address from,
        address to,
        uint tokenId
    ) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the null address");

        _approval(owner, address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    //实现IERC721的transferFrom,非安全转账.调用_transfer函数
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _transfer(owner, from, to, tokenId);
    }

    /**
     * 安全转账函数.安全的将tokenId代币从from转移到to,
     * 会检查合约接收者是否了解ERC721协议,以防代币被永久锁定.
     * 调用了_transfer函数和_checkOnERC721Received函数
     * 条件:
     * 1. from不是0地址
     * 2. to不能是0地址
     * 3. tokenId代币必须存在,并且被from拥有
     * 4. 如果to是智能合约,它必须支持IERC721Receiver-onERC721Received
     */
    function _safeTransfer(
        address owner,
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    //实现IERC721的safeTransferFrom,安全转账,调用_safeTransfer函数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to,tokenId, _data);
    }

     // safeTransferFrom重载函数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** 
     * 铸造函数.通过调整_balances和_owners变量来铸造tokenId并转账给to，
     * 同时释放Transfer事件.铸造函数.
     * 通过调整_balances和_owners变量来铸造tokenId并转账给to,同时释放Transfer事件.
     * 这个mint函数所有人都能调用，实际使用需要开发人员重写，加上一些条件
     * 条件:
     * 1. tokenId尚不存在
     * 2. to不是0地址
     */
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    //销毁函数,通过调整_balances和_owners变量来销毁tokenId,同时释放Transfer事件.
    //条件：tokenId存在
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");

        _approval(owner, address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    //_checkOnERC721Received函数,用于在to为合约的时候调用IERC721Receivr-onERC721Received,以防tokenId被转入黑洞
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
    
    //实现IERC721Metadata的tokenURI函数,查询metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_owners[tokenId] != address(0), "token not exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * 计算{tokenURI}的BaseURI,tokenURI就是把baseURI和tokenId拼接在一起,需要开发重写
     * BAYC的baseURI为ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
}