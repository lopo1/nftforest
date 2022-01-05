// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./VRFConsumerBase.sol";
import "./Owned.sol";

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {TRC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface TRC721TokenReceiver {
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

contract TRC721Holder is TRC721TokenReceiver {
    function onTRC721Received(address, address, uint256, bytes memory) external virtual override returns (bytes4) {
        return this.onTRC721Received.selector;
    }
}

contract CrazyForest is TRC721Holder, VRFConsumerBase, Owned {
    // solidity 0.8.0 以上版本已默认检查溢出，可以不使用SafeMath
    // 开启编译优化，共占用256的空间，节省gas开销
    struct Tree {
        uint8 magicNum; //神奇果树的数量
        uint8 isNFT;
        uint8 isOpen;
        uint8 treeIndex;
        uint32 timestamp;
        uint32 num;
        uint32 cont;
        uint64 totalCont;
        uint64 price;
    }

    struct TreeInfo {
        uint64 treeIndex;
        uint64 cont;
        uint128 totalCont;
    }

    struct Income {
        uint32 dividendDay; //分红起始日
        uint32 minIndex; //最小有效树下标
        uint64 ref; //推荐
        uint64 lottery; //抽奖
        uint64 bonus; //大奖
    }

    struct DividendCheck {
        uint32 treeIndex; //树坐标
        uint32 minIndex; //本次分红最小树坐标
        uint64 value; //分红金额
        uint64 totalShare; //单个贡献值累计分红金额
        uint64 sumCont; //本次分红总贡献值
    }

    struct CheckPoint {
        uint64  treeIndex; // 最大树坐标
        uint64  minIndex; // 最小树坐标
        uint128  value; 
    }

     struct BackGround {
        uint128 index;
        uint128 price;
        string url;
    }

    struct Request {
        uint64 requestType;
        uint64 valid;
        uint128 value;
    }
    
    // 占用一个256位存储槽
    struct GameCondition {
        uint8  flag; // released(4) | start(2) | preBuy(1)
        uint16 dayOffset;
        uint16 currentDay;
        uint16 minDay;
        uint24 roundOffset;
        uint24 currentRound;
        uint24 remainTime;
        uint32 minIndex; // 最小的有效的树下标
        uint32 treeNum; // 当前下标
        uint32 currentMagic;
        uint32 currentNFT;
    }

    // 占用一个256位存储槽
    struct GameState {
        uint32 timestamp;
        uint48 totalContributes;
        uint56 ecology;
        uint56 community;
        uint64 bonus;
    }
    
    // 为了降低gas开销，如需修改下面的值，请在467行的函数内修改
    // uint256[] private _trees = [1, 2, 5, 10, 20, 50, 100, 200];
    // uint256[] private _increase = [600, 300, 60, 60, 30];
    // uint256 private _singlePrice = 158000000;

    GameCondition private _gCondition = GameCondition(1, 0, 0, 0, 0, 0, 86400, 0, 0, 0, 0);
    GameState private _gState = GameState(0, 0, 0, 0, 0);

    mapping(uint256 => DividendCheck) private _dividendCheck;
    mapping(uint256 => CheckPoint) private _lotteryCheck;
    mapping(uint256 => CheckPoint) private _magicCheck;
    mapping(address => Income) private _userIncome;
    mapping(address => TreeInfo[]) private _userTrees;
    // mapping(address => mapping(uint256 => uint256)) private _userWater;
    mapping(address => uint256) private _bonusTaken;
    mapping(uint256 => Tree)  private _treeList;
    mapping(uint256 => address) private _treeOwners;
    uint256[] private _magicTrees;
    uint256[] private _nftTrees;
    mapping(uint256 => uint256) private _nftTokens;
    mapping(address => address) _super;
    mapping(address => uint256) _userBox;
    address[] _boxUsers;
    BackGround[] _bgs;
    mapping(address => uint256[]) _userBgs;
    mapping(bytes32 => Request) _requests;
    mapping(bytes32 => uint256) _rands;

    mapping(address => uint256) private _admins;
    address public stakeToken;
    address private _first;
    address private _nft;
    uint256 private _tokenId = 1;

    bytes32 private s_keyHash;
    uint256 private s_fee;

    constructor(address _stakeToken, address _f, address _n, address vrfCoordinator, address win, address winkMid, bytes32 keyHashValue, uint256 feeValue)
    VRFConsumerBase(vrfCoordinator, win, winkMid){
        _admins[msg.sender] = 1;
        stakeToken = _stakeToken;
        _first = _f;
        _nft = _n;
        s_keyHash = keyHashValue;
        s_fee = feeValue;
    }

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Direct(address indexed user, address superUser, uint256 amount);
    event InDirect(address indexed user, address inSuper, uint256 amount);
    event BuyTree(address indexed user, uint256 price);
    event Lottery(address indexed user, uint256 amount);
    event DividendTake(address indexed user, uint256 amount);
    event PoolTake(address indexed user, uint256 amount);
    event RefTake(address indexed user, uint256 amount);
    event NftUse(uint256 tokenId);
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event ReciveRand(bytes32 indexed requestId, uint256 randomness);
    event MagicCheck(uint64 cIndex, uint64 treeIndex, uint64 minIndex, uint64 magicNum);
    event AdminSet(address admin);
    event AdminUnset(address admin);
    event FirstUpdate(address first);

    modifier activated() {
        require(_super[msg.sender] != address(0) || msg.sender == _first, "Must activate first");
        _;
    }

    modifier started() {
        require((_gCondition.flag & 2) == 2, "Not started");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender] == 1, "Only admin can change items");
        _;
    }

    function _rollDice(uint256 userProvidedSeed, address roller) private returns (bytes32 requestId)
    {
        require(winkMid.balanceOf(address(this)) >= s_fee, "Not enough WIN to pay fee");
        requestId = requestRandomness(s_keyHash, s_fee, userProvidedSeed);
        emit DiceRolled(requestId, roller);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (_rands[requestId] == 0) {
            _rands[requestId] = randomness;
            emit ReciveRand(requestId, randomness);
        }
    }

    function processRandomness(bytes32 requestId) external onlyAdmin {
        uint256 randomness =  _rands[requestId];
        Request storage r = _requests[requestId];
        require(r.valid == 1, "finished!");
        require(randomness != 0, "please wait!");
        if (r.requestType == 1) {
            // 抽取神奇果树
            uint256 currentMagic = r.value;
            require(_gCondition.currentMagic == currentMagic, "Duplicated!");
            CheckPoint memory mc = _magicCheck[currentMagic];
            uint256 mNum = mc.value;
            require(mNum > 0, "Not time!");
            uint256 beginIndex = 0;
            if (currentMagic > 0) {
                beginIndex = _magicCheck[currentMagic-1].treeIndex + 1;
            }
            beginIndex = Math.max(beginIndex, mc.minIndex);
            
            while(true) {
                uint256 index = _getRandTree(randomness, beginIndex, mc.treeIndex);
                if(_treeList[index].magicNum < _treeList[index].num) {
                    _treeList[index].magicNum += 1;
                    _magicTrees.push(index);
                    mNum -= 1;
                    if(mNum == 0) {
                        break;
                    }
                }
                randomness = uint256(keccak256(abi.encodePacked(randomness, uint256(mNum))));
            }
            _gCondition.currentMagic += uint32(mc.value);
            r.valid = 0;
        } else if (r.requestType == 2) {
            // 抽取NFT
            uint256 currentNFT = r.value;
            require(_gCondition.currentNFT == currentNFT, "Duplicated!");
            uint256 maxIndex = currentNFT * 20 + 20;
            uint256 minIndex = 0;
            uint256 gMinIndex = _gCondition.minIndex;
            uint256 sum = 0;
            while(minIndex < maxIndex && _magicTrees[minIndex] < gMinIndex) {
                ++minIndex;
            }
            uint256[] memory indexList = new uint256[](maxIndex - minIndex + 1);
            for(uint256 i = minIndex; i < maxIndex; ++i) {
                uint256 ti = _magicTrees[i];
                if (_treeList[ti].isNFT == 0) {
                    indexList[sum] = ti;
                    sum++;
                }
            }
            if (sum > 0) {
                uint256 nftTokenId = _getTokenId();
                require(nftTokenId != 0, "No NFT left!");
                uint256 rand = randomness % sum;
                uint256 tIndex = indexList[rand];
                _treeList[tIndex].isNFT = 1;
                _nftTrees.push(tIndex);
                _nftTokens[tIndex] = nftTokenId;
            }
            _gCondition.currentNFT += 1;
            r.valid = 0;
        } else if(r.requestType == 3){
            // 抽奖
            require(_gCondition.currentRound == r.value, "Duplicated!");
            CheckPoint memory lCheck = _lotteryCheck[r.value];
            uint256 index = _getRandTree(randomness, lCheck.minIndex, lCheck.treeIndex);
            address user = _treeOwners[index];
            TransferHelper.safeTransfer(stakeToken, user, lCheck.value);
            // _userIncome[user].lottery += r.v2;
            _gCondition.currentRound += 1;
            r.valid = 0;
            emit Lottery(user, lCheck.value);
        } else {
            require((_gCondition.flag & 2) == 0, "Duplicated!");
            uint256 len = _boxUsers.length;
            if (len > 0) {
                uint256 num = (len + 29) / 30;
                uint256 rand = randomness % len;
                uint256 tCont = _gState.totalContributes;
                uint256 tIndex = _gCondition.treeNum;
                for(uint256 i = 0; i < num; ++i) {
                    address user = _boxUsers[rand];
                    tCont += 1;
                    _treeList[tIndex] = Tree(0, 0, 0, 0, uint32(_userBox[user]), 1, 1, uint64(tCont), uint64(_treePrice(0)));
                    _treeOwners[tIndex] = user;
                    _userTrees[user].push(TreeInfo(uint64(tIndex), 1, 1));
                    //add magic check
                    if(tCont % 500 == 0) {
                        _magicCheck[tCont / 500 - 1] = CheckPoint(uint64(tIndex), 0, 1);
                        emit MagicCheck(uint64(tCont / 500 - 1), uint64(tIndex), 0, 1);
                    }
                    tIndex += 1;
                    rand += 30;
                    if(rand >= len) {
                        rand -= len;
                    }
                }
                _gState.totalContributes += uint48(tCont);
                _gCondition.treeNum = uint32(tIndex);
            }
            _startGame();
        }
        emit DiceLanded(requestId, 0);
    }

    function _startGame() private {
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.dayOffset = uint16((block.timestamp + 28800) / 86400);
        _gCondition.roundOffset = uint24(block.timestamp / 7200);
        _gCondition.flag |= 2; // start
    }

    function _getRandTree(uint256 r, uint256 minIndex, uint256 maxIndex) private view returns (uint256) {
        uint256 baseCont = 0;
        if (minIndex > 0) {
            baseCont = _treeList[minIndex-1].totalCont;
        }
        uint256 totalCont = _treeList[maxIndex].totalCont - baseCont;
        r = (r % totalCont) + baseCont;
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if(_treeList[midIndex].totalCont <= r) {
                minIndex = midIndex;
            } else {
                maxIndex = midIndex;
            }
        }
        if(_treeList[minIndex].totalCont > r) {
            return minIndex;
        } else {
            return maxIndex;
        }
    }

    function withdrawWIN(address to, uint256 value) external onlyAdmin {
        token.approve(winkMidAddress(), value);
        require(winkMid.transferFrom(address(this), to, value), "Not enough WIN");
    }

    function setKeyHash(bytes32 keyHashValue) external onlyAdmin {
        s_keyHash = keyHashValue;
    }

    function setAdmin(address admin) external onlyAdmin {
        _admins[admin] = 1;
        emit AdminSet(admin);
    }

    function unsetAdmin(address admin) external onlyAdmin {
        _admins[admin] = 0;
        emit AdminUnset(admin);
    }

    function setFirst(address firstValue) external onlyAdmin {
        _first = firstValue;
        emit FirstUpdate(firstValue);
    }

    function keyHash() external view returns (bytes32) {
        return s_keyHash;
    }

    function setFee(uint256 feeValue) external onlyAdmin {
        s_fee = feeValue;
    }

    function fee() external view returns (uint256) {
        return s_fee;
    }

    function first() external view returns (address) {
        return _first;
    }

    // 树的贡献值，树的类型在此修改，internal gas消耗更少
    function _treeCont(uint256 index) internal pure returns (uint256) {
        uint256[8] memory _treeContValue = [uint256(1), 2, 5, 10, 20, 50, 100, 200];
        require(index < _treeContValue.length, "Index error");
        return _treeContValue[index];
    }

    // 树的价格，树的单价在此修改，internal gas消耗更少
    function _treePrice(uint256 index) internal view returns (uint256) {
        uint256 _singlePrice = 158000000;
        return _treeCont(index) * _singlePrice * (_gState.totalContributes / 1000 * 5 + 1000) / 1000;
    }
    
    // 更新剩余时间，时间增加幅度值在此修改
    function _updateTime(uint256 cont, uint256 timeGap) private {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 200000) {
            cont *= 30;
        } else if (totalCont > 100000) {
            cont *= 60;
        } else if (totalCont > 50000) {
            cont *= 300;
        } else {
            cont *= 600;
        }
        _gCondition.remainTime = uint24(Math.min(_gCondition.remainTime + cont - timeGap, _getLimit()));
    }

    // 树的贡献值，供前端调用
    function treeCont(uint256 index) external pure returns (uint256) {
        return _treeCont(index);
    }
    // 树的价格，供前端调用
    function treePrice(uint256 index) external view returns (uint256) {
        return _treePrice(index);
    }

    // 背景列表
    function allBg() external view returns (BackGround[] memory){
        return _bgs;
    }

    // 游戏是否开始
    function isStart() external view returns (bool) {
        return (_gCondition.flag & 2) == 2;
    }

    // 游戏是否结束
    function isEnd() external view returns (bool) {
        return _ifEnd();
    }

    // 时间
    function checkPoint() external view returns (uint256) {
        return _gState.timestamp;
    }

    // 神奇果树数量
    function magicTreeNum() external view returns (uint256) {
        return _magicTrees.length;
    }

    // 剩余时间
    function remainTime() public view returns (uint256) {
        if((_gCondition.flag & 2) == 2) {
            uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
            if(timeGap > _gCondition.remainTime) {
                return 0;
            }
            return _gCondition.remainTime - timeGap;
        } else {
            return _gCondition.remainTime;
        }
    }
    
    // 返回订单数
    function orderNum() external view returns (uint32) {
        return _gCondition.treeNum;
    }

    // 返回订单信息
    function treeInfo(uint256 idx) external view returns (Tree memory) {
        return _treeList[idx];
    }

    // 返回订单owner
    function treeOwner(uint256 idx) external view returns (address) {
        return _treeOwners[idx];
    }

    // 用户是否激活
    function isActivate(address account) external view returns (bool){
        return _super[account] != address(0) || account == _first;
    }

    // 用户背景列表
    function bgOf(address account) external view returns (uint256[] memory){
        return _userBgs[account];
    }

    // 累计分红
    function totalDividend() external view returns (uint256){
        return _dividendCheck[_getDay()].value;
    }

    // 累计奖池
    function totalPool() external view returns (uint256){
        if ((_gCondition.flag & 4) == 4) {
            return _gState.bonus * 5;
        }
        return _gState.bonus;
    }

    // 累计生态基金
    function totalEcology() external view returns (uint256) {
        return _gState.ecology;
    }
    
    // 累计委员会基金
    function totalCommunity() external view returns (uint256) {
        return _gState.community;
    }

    // 抽奖奖池
    function totalLottery() external view returns (uint256){
        return _lotteryCheck[_getRound()].value;
    }

    // 累计贡献值
    function totalContribute() external view returns (uint256){
        return _gState.totalContributes;
    }

    // 用户的盲盒
    function boxOf(address account) external view returns (uint256){
        return _userBox[account];
    }

    // 返回用户所有的树，树里包含了树种信息，前端处理以提高效率
    function treeOf(address account) external view returns (Tree[] memory) {
        TreeInfo[] memory ut = _userTrees[account];
        Tree[] memory tl = new Tree[](ut.length);       
        for(uint i = 0; i < ut.length; ++i) {
            tl[i] = (_treeList[ut[i].treeIndex]);
        }
        return tl;
    }

    // 上面的函数返回了所有的树，树的信息包含了是否是神奇果树
    // function magicTreeOf(address account) external view returns (MagicTree[] memory){
    //    
    // }

    // 用户未领取的分红
    function dividendOf(address account) external view returns (uint256){
        Income memory uIncome = _userIncome[account];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[account];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            uint256 cont = 0;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    cont += ut[i].cont;
                } else {
                    break;
                }
            }
            sum += dc.value * cont / dc.sumCont;
        }
        return sum;
    }

    // 用户未领取的奖池
    function poolOf(address account) external view returns (uint256) {
        uint256 amount = _userIncome[account].bonus;
        if ((_gCondition.flag & 4) == 4) {
            if(_userTrees[account].length > 0 && _gState.totalContributes > 101) {
                uint256 cont = _userTrees[account][_userTrees[account].length - 1].totalCont;
                cont -= _bonusTaken[account];
                amount += uint64(_gState.bonus * cont / (_gState.totalContributes - 101));      
            }
        }
        return amount;
    }

    // 用户未领取的推荐奖励
    function refOf(address account) external view returns (uint256){
        return _userIncome[account].ref;
    }

    // 我的贡献值, 不建议调用，因为treeOf中包含了贡献值，前端做计算即可，这样可以提升运行效率
    // function userC(address account) external view returns (uint256){
    //     uint256 sum = 0;
    //     uint256[] memory ut = _userTrees[account];
    //     for(uint i = 0; i < ut.length; ++i) {
    //         sum += _treeList[ut[i]].cont;
    //     }
    //     return sum;
    // }

    // 用户今日浇水次数
    // function waterCountOf(address account) external view returns (uint256){
    //     return _userWater[account][_getDay()];
    // }

    // 激活用户
    function activate(address superUser) external {
        require(_super[superUser] != address(0) || superUser == _first, "Super not activated");
        require(_super[msg.sender] == address(0) && msg.sender != _first, "Already activated");
        if ((_gCondition.flag & 2) == 2) {
            _userIncome[msg.sender].dividendDay = uint32(_getDay());
        } else {
            _userIncome[msg.sender].dividendDay = 0; // game not start
        }
        _super[msg.sender] = superUser;
    }

    // 购买背景
    function buyBg(uint256 index) external activated started {
        require(index < _bgs.length, "Bg index error");
        // require(_haveBg(msg.sender, index) == false, "Already have bg");
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) external activated started {
        require(num > 0, "Must greater than zero");
        uint256 tIndex = _gCondition.treeNum;
        uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
        require(timeGap < _gCondition.remainTime, "Time is over!");
        uint256 price = _treePrice(index) * num;
        uint256 direct = 0;
        address superUser = _super[msg.sender];
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), price);
        if (superUser != address(0)) {
            direct = price * 10 / 100;
            _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
            emit Direct(msg.sender, superUser, direct);
        }
        uint256 indirect = 0;
        address inSuper = _super[superUser];
        if (inSuper != address(0)) {
            indirect = price * 5 / 100;
            _userIncome[inSuper].ref = _userIncome[inSuper].ref + uint64(indirect);
            emit InDirect(msg.sender, inSuper, indirect);
        }

        //update trees
        uint256 cont = _treeCont(index) * num;
        uint256 preTotalCont = _gState.totalContributes;
        uint256 totalCont = preTotalCont + cont;
        _gState.totalContributes = uint48(totalCont);
        _treeList[tIndex] = Tree(0, 0, 0, uint8(index), uint32(block.timestamp), uint32(num), uint32(cont), uint64(totalCont), uint64(price / cont));
        _treeOwners[tIndex] = msg.sender;
        //add magic check
        uint256 mNum = totalCont / 500 - preTotalCont / 500;
        if(mNum > 0) {
            _magicCheck[preTotalCont / 500] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(mNum));
            emit MagicCheck(uint64(preTotalCont / 500), uint64(tIndex), uint64(_gCondition.minIndex), uint64(mNum));
        }

        uint256 idx = _getDay();
        _dividendCheck[idx] = DividendCheck(uint32(tIndex), 0, uint64(_dividendCheck[idx].value + price * 38 / 100), 0, uint64(totalCont));
        idx = _getRound();
        _lotteryCheck[idx] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(_lotteryCheck[idx].value + price * 5 / 100));

         // add users  tree
        TreeInfo[] storage ut = _userTrees[msg.sender];
        totalCont = cont; //user total cont
        if(ut.length > 0) {
            totalCont += ut[ut.length-1].totalCont;
        }
        ut.push(TreeInfo(uint64(tIndex), uint64(cont), uint128(totalCont)));

        _gState.bonus += uint64(price * 15 / 100);
        _gState.ecology += uint56(price * 12 / 100);
        _gState.community += uint56(price * 30 / 100 - direct - indirect);
        _gState.timestamp = uint32(block.timestamp);
        _gCondition.treeNum = uint32(tIndex + 1);

        _updateTime(cont, timeGap);

        emit BuyTree(msg.sender, price);
    }

    function _getDay() private view returns (uint256) {
        return (block.timestamp + 28800) / 86400 - _gCondition.dayOffset;
    }

    function _getRound() private view returns (uint256) {
        return block.timestamp / 7200 - _gCondition.roundOffset;
    }

    // 浇水
    // function water() external activated started {
    //     uint256 day = _getDay();
    //     _userWater[msg.sender][day] += 1;
    // }

    // 开启魔法树的NFT
    function openMagicTree(uint256 index) external activated started {
        require(index < _userTrees[msg.sender].length, "Index error");
        uint256 tIndex = _userTrees[msg.sender][index].treeIndex;
        Tree storage t = _treeList[tIndex];
        require(t.isNFT == 1, "Not Magic tree!");
        require(t.isOpen == 0, "It is opened!");
        uint256 tokenId = _nftTokens[tIndex];
        IERC721(_nft).transferFrom(address(this), msg.sender, tokenId);
        t.isOpen = 1;
        emit NftUse(tokenId);
    }

    // 提取分红
    function dividendTake() external activated started {
        Income storage uIncome = _userIncome[msg.sender];
        uint256 dDay = uIncome.dividendDay;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentDay = _gCondition.currentDay;
        TreeInfo[] memory ut =  _userTrees[msg.sender];
        for(; dDay < currentDay; ++dDay) {
            DividendCheck memory dc = _dividendCheck[dDay];
            uint256 minIndexCheck = dc.minIndex;
            uint256 maxIndexCheck = dc.treeIndex;
            uint256 cont = 0;
            while(ut[minIndex].treeIndex < minIndexCheck) {
                ++minIndex;
            }
            for(uint256 i = minIndex; i < ut.length; ++i) {
                if(ut[i].treeIndex <= maxIndexCheck) {
                    cont += ut[i].cont;
                } else {
                    break;
                }
            }
            sum += dc.value * cont / dc.sumCont;
        }
        if (sum > 0) {
            TransferHelper.safeTransfer(stakeToken, msg.sender, sum);
        }
        uIncome.dividendDay = uint32(currentDay);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
    }

    // 新增：提取推荐奖励，降低购买树苗的收费，合并转账，降低转账手续费
    function refTake() external activated started {
        uint256 amount = _userIncome[msg.sender].ref;
        require(amount > 0, "No remain ref");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userIncome[msg.sender].ref = 0;
        emit RefTake(msg.sender, amount);
    }

    // 提取奖池收益
     function poolTake() external activated started {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        uint256 amount = _userIncome[msg.sender].bonus;
        if(_userTrees[msg.sender].length > 0 && _gState.totalContributes > 101) {
            uint256 cont = _userTrees[msg.sender][_userTrees[msg.sender].length - 1].totalCont;
            cont -= _bonusTaken[msg.sender];
            amount += uint64(_gState.bonus * cont / (_gState.totalContributes - 101));
            _bonusTaken[msg.sender] += cont;
        }
        
        require(amount > 0, "No remain bonus!");
        TransferHelper.safeTransfer(stakeToken, msg.sender, amount);
        _userIncome[msg.sender].bonus = 0;
        emit PoolTake(msg.sender, amount);
    }

    // 购买盲盒
    function buyBox() external activated {
        require(_userBox[msg.sender] == 0, "Only once");
        require((_gCondition.flag & 1) == 1, "Activity end");
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, _first, 5000000);
        _userBox[msg.sender] = block.timestamp;
        _boxUsers.push(msg.sender);
    }

    // ---
    function openBox() external onlyAdmin {
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(4, 1, 0);
        _gCondition.flag ^= 1; //preBuy = 0
        //for test
        fulfillRandomness(requestId, seed);
    }

    function addBg(uint256 _price, string memory _url) external onlyAdmin {
        _bgs.push(BackGround(uint128(_bgs.length), uint128(_price), _url));
    }
    
    // 抽奖
    function lottery() external onlyAdmin started {
        uint256 round = _getRound();
        uint256 currentRound = _gCondition.currentRound;
        require(round > currentRound, "It is not time yet!!");
        if (_lotteryCheck[currentRound].value > 0) {
            uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
            bytes32 requestId = _rollDice(seed, address(this));
            _requests[requestId] = Request(3, 1, uint128(currentRound));
            //for test
            fulfillRandomness(requestId, seed);
        } else {
            _gCondition.currentRound += 1;
        }
    }
    
    // 抽神奇果树
    function genMagicTree() external onlyAdmin started {
        uint256 currentMagic = _gCondition.currentMagic;
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(1, 1, uint128(currentMagic));
        //for test
        fulfillRandomness(requestId, seed);
    }
    
    // 抽取NFT
    function genNFT() external onlyAdmin {
        uint256 nftCount = _magicTrees.length / 20;
        require(_gCondition.currentNFT < nftCount, "It is not time yet!!");
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(2, 1, uint128(_gCondition.currentNFT));
        //for test
        fulfillRandomness(requestId, seed);
    }

    function ecologyTake(address account) external onlyAdmin {
        if (_gState.ecology > 0) {
            TransferHelper.safeTransfer(stakeToken, account, _gState.ecology);
            _gState.ecology = 0;
        }
    }

    function communityTake(address account) external onlyAdmin {
        if (_gState.community > 0) {
            TransferHelper.safeTransfer(stakeToken, account, _gState.community);
            _gState.community = 0;
        }
    }

    function dividend() external onlyAdmin {
        uint256 day = _getDay();
        uint256 currentDay = _gCondition.currentDay;
        require(day > currentDay, "It is not time yet!!");
        DividendCheck storage dCheck = _dividendCheck[currentDay];
        uint256 dValue = dCheck.value;
        uint256 maxIndex = dCheck.treeIndex;
        uint256 sumCont = dCheck.sumCont;
        uint256 minIndex = _gCondition.minIndex;
        uint256 minDay = _gCondition.minDay;
        if (minIndex > 0) {
            sumCont -= _treeList[minIndex - 1].totalCont;
        }
        uint256 totalShare = dValue / sumCont;
        if(currentDay > 0) {
            totalShare += _dividendCheck[currentDay-1].totalShare;
        }

        dCheck.minIndex = uint32(minIndex);
        dCheck.totalShare = uint32(totalShare);
        dCheck.sumCont = uint32(sumCont);

        // update minDay
        uint256 minShare = 0;
        if (minDay > 0) {
            minShare = _dividendCheck[minDay - 1].totalShare;
        }

        for(; minDay < currentDay; ++minDay) {
            DividendCheck memory dc = _dividendCheck[minDay];
            Tree memory t = _treeList[dc.treeIndex];
            if (totalShare - minShare < t.price * 3) {
                maxIndex = dc.treeIndex;
                break;
            }
            minShare = dc.totalShare;
            minIndex = dc.treeIndex + 1;
        }
        // update minIndex
        totalShare -= minShare;
        while(minIndex + 1 < maxIndex) {
            uint256 midIndex = (minIndex + maxIndex) >> 1;
            if (totalShare < _treeList[midIndex].price * 3) {
                maxIndex = midIndex;
            } else {
                minIndex = midIndex;
            }
        }
        if (totalShare >= _treeList[minIndex].price * 3) {
            minIndex += 1;
        }

        _gCondition.minIndex = uint32(minIndex);
        _gCondition.minDay = uint16(minDay);
        _gCondition.currentDay += 1;
    }

    function poolRelease() external onlyAdmin {
        require(_ifEnd(), "It is not time yet!!");
        require((_gCondition.flag & 4) == 0, "It is released!!");
        uint256 reward = _gState.bonus * 40 / 100;
        uint256 secondContribute = Math.min(100, _gState.totalContributes - 1);
        uint256 leftCont = secondContribute;
        if (reward > 0) {
            uint256 idx = _gCondition.treeNum - 1;
            Tree memory t = _treeList[idx];
            address user = _treeOwners[idx];
            _userIncome[user].bonus += uint64(reward);
             _bonusTaken[user] += 1;
            if (t.cont > 1) {
                uint256 cont = Math.min(t.cont-1, 100);
                uint256 b = reward * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
        
            while(leftCont > 0) {
                idx -= 1;
                t = _treeList[idx];
                user = _treeOwners[idx];
                uint256 cont = Math.min(t.cont, leftCont);
                uint256 b = reward * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
                _bonusTaken[user] += cont;
            }
            _gState.bonus -= uint64(reward << 1);
        }
        _gCondition.flag ^= 4; //released
    }

    // 前端判断即可
    // function _haveBg(address account, uint256 index) private view returns (bool) {
    //     uint256 len = _userBgs[account].length;
    //     for (uint256 i = 0; i < len; i++) {
    //         if (_userBgs[account][i] == index) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    function _isSleep(uint256 blockTime) private pure returns (bool) {
        return (blockTime + 25200) % 86400 < 21600;
    }

    function _timeGap(uint256 begin, uint256 end) private pure returns (uint256) {
        if(!_isSleep(begin) && !_isSleep(end)) {
            if ((begin + 25200) % 86400 <= (end + 25200) % 86400) {
                return (end - begin) - (end - begin) / 86400 * 21600;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600 - 21600;
            }
        } else {
            if(_isSleep(begin)) {
                begin = (begin + 25200) / 86400 * 86400 + 21600;
            }
            if(_isSleep(end)) {
                end = (end + 25200) / 86400 * 86400;
            }
            if(begin >= end) {
                return 0;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600;
            }

        }
    }
    
    // private 消耗gas更少
    function _ifEnd() private view returns (bool){
        uint256 dura = _timeGap(_gState.timestamp, block.timestamp);
        return dura >= _gCondition.remainTime;
    }

    function ifEnd() external view returns (bool){
        return _ifEnd();
    }

    function _getLimit() private view returns (uint256) {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 50000) {
            return 86400;
        } else if (totalCont > 20000) {
            return 172800;
        } else if (totalCont > 10000) {
            return 345600;
        } else {
            return 691200;
        }
    }

    function _getTokenId() internal returns (uint256) {
        IERC721Enumerable nf = IERC721Enumerable(_nft);
        uint256 balance = nf.balanceOf(address(this));
        for (uint256 i = 0; i < balance; i++) {
            uint256 tId = nf.tokenOfOwnerByIndex(address(this), i);
            if (tId > _tokenId) {
                _tokenId = tId;
                return tId;
            }
        }
        return 0; //0表示没有剩余的nft，不要使用0作为nft tokenid
    }
}