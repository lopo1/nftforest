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

contract CrazyForest is VRFConsumerBase, Owned {
    // solidity 0.8.0 以上版本已默认检查溢出，可以不使用SafeMath
    // 开启编译优化，共占用256的空间，节省gas开销
    struct Tree {
        uint16 treeIndex;
        uint48 timestamp;
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
        uint32 dividendRound; //分红起始轮
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
        uint24 dayOffset;
        uint24 dividendRound;
        uint24 minDividendRound;
        uint24 lotteryRound;
        uint24 remainTime;
        uint32 minIndex; // 最小的有效的树下标
        uint32 treeNum; // 当前下标
        uint64 timestamp;
    }

    // 占用一个256位存储槽
    struct GameState {
        uint64 totalContributes;
        uint64 ecology;
        uint64 community;
        uint64 bonus;
    }

    GameCondition private _gCondition = GameCondition(1, 0, 0, 0, 0, 86400, 0, 0, 0);
    GameState private _gState = GameState(0, 0, 0, 0);

    mapping(uint256 => DividendCheck) private _dividendCheck;
    mapping(uint256 => CheckPoint) private _lotteryCheck;
    mapping(uint256 => address) private _lotteryWinner;
    mapping(address => Income) private _userIncome;
    mapping(address => TreeInfo[]) private _userTrees;
    mapping(uint256 => Tree)  private _treeList;
    mapping(uint256 => address) private _treeOwners;
    mapping(address => address) _super;
    BackGround[] _bgs;
    mapping(address => uint256[]) _userBgs;
    mapping(bytes32 => Request) _requests;
    mapping(bytes32 => uint256) _rands;

    mapping(address => uint256) private _admins;
    mapping(uint256 => mapping(address => uint256)) private _dailyTreeNum;
    TRC20Interface internal usdt;
    address private _first;
    uint256 private _tokenId = 1;

    bytes32 private s_keyHash;
    uint256 private s_fee;
    uint256 public startTime;
    

    constructor(address _usdt, address _f, address vrfCoordinator, address win, address winkMid, bytes32 keyHashValue, uint256 feeValue)
    VRFConsumerBase(vrfCoordinator, win, winkMid){
        _admins[msg.sender] = 1;
        usdt = TRC20Interface(_usdt);
        _first = _f;
        s_keyHash = keyHashValue;
        s_fee = feeValue;
        _super[_f] = _f;
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
    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event ReciveRand(bytes32 indexed requestId, uint256 randomness);
    event AdminSet(address admin);
    event AdminUnset(address admin);
    event FirstUpdate(address first);
    event DoDividend(uint256 round, uint256 minIndex, uint256 minRound, uint256 value);
    event ReleasePool(address last, uint256 value);

    modifier activated() {
        require(_super[msg.sender] != address(0), "Must activate first");
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
        if (r.requestType == 3){
            // 抽奖
            require(_gCondition.lotteryRound == r.value, "Duplicated!");
            CheckPoint memory lCheck = _lotteryCheck[r.value];
            uint256 minIndex = _lotteryCheck[r.value - 1].treeIndex + 1;
            uint256 index = _getRandTree(randomness, minIndex, lCheck.treeIndex);
            address user = _treeOwners[index];
            usdt.transfer(user, lCheck.value);
            // _userIncome[user].lottery += r.v2;
            _lotteryWinner[r.value] = user;
            _gCondition.lotteryRound += 1;
            r.valid = 0;
            emit Lottery(user, lCheck.value);
        }
        emit DiceLanded(requestId, 0);
    }

    function startGame() external onlyAdmin {
        _gCondition.dayOffset = uint24((block.timestamp + 28800) / 86400);
        _gCondition.lotteryRound = uint24(_getRound());
        _gCondition.dividendRound = uint24(_getDividendRound());
        _gCondition.minDividendRound = uint24(_getDividendRound());
        _gCondition.flag |= 2; // start
        startTime = block.timestamp;
        _gCondition.timestamp = uint64((block.timestamp + 28800) / 86400 * 86400 - 28800 + 864000);
        _userIncome[_first].dividendRound = uint32(_getDividendRound());
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

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function unprocessLottery() external view returns (uint256) {
        return _getRound() - _gCondition.lotteryRound;
    }

    function unprocessDividend() external view returns (uint256) {
        return _getDividendRound() - _gCondition.dividendRound;
    }

    function lotteryInfo(uint256 _round) external view returns (uint256) {
        return _lotteryCheck[_round].value;
    }

    function dividendInfo(uint256 _round) external view returns (uint256) {
        return _dividendCheck[_round].value;
    }

    // 树的贡献值，树的类型在此修改，internal gas消耗更少
    function _treeCont(uint256 index) internal pure returns (uint256) {
        uint256[8] memory _treeContValue = [uint256(1), 2, 5, 10, 20, 50, 100, 200];
        require(index < _treeContValue.length, "Index error");
        return _treeContValue[index];
    }

    // 树的价格，树的单价在此修改，internal gas消耗更少
    function _treePrice(uint256 index) internal view returns (uint256) {
        uint256 _singlePrice = 30000000;
        return _treeCont(index) * _singlePrice * (_gState.totalContributes / 40 + 1000) / 1000;
    }
    
    // 更新剩余时间，时间增加幅度值在此修改
    function _updateTime(uint256 cont) private {
        uint256 timeGap = _timeGap(_gCondition.timestamp, block.timestamp);
        require(timeGap < _gCondition.remainTime, "Time is over!");
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 100000) {
            cont *= 30;
        } else {
            cont *= 60;
        }
        _gCondition.remainTime = uint24(Math.min(_gCondition.remainTime + cont - timeGap, _getLimit()));
        _gCondition.timestamp = uint64(block.timestamp);
    }

    // 树的贡献值，供前端调用
    function treeCont(uint256 index) external pure returns (uint256) {
        return _treeCont(index);
    }
    // 树的价格，供前端调用
    function treePrice(uint256 index) external view returns (uint256) {
        return _treePrice(index);
    }

    // 推荐人
    function superAccount(address account) external view returns (address) {
        return _super[account];
    }

    // 背景列表
    function allBg() external view returns (BackGround[] memory){
        return _bgs;
    }

    // 游戏是否开始
    function isStart() external view returns (bool) {
        return (_gCondition.flag & 2) == 2;
    }

    // 时间
    function checkPoint() external view returns (uint256) {
        return _gCondition.timestamp;
    }

    // 剩余时间
    function remainTime() public view returns (uint256) {
        uint256 day = _getDay();
        if (day < 10) {
            return _gCondition.remainTime;
        }
        if((_gCondition.flag & 2) == 2) {
            uint256 timeGap = _timeGap(_gCondition.timestamp, block.timestamp);
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
        return _super[account] != address(0);
    }

    // 用户背景列表
    function bgOf(address account) external view returns (uint256[] memory){
        return _userBgs[account];
    }

    // 累计分红
    function totalDividend() external view returns (uint256){
        return _dividendCheck[_getDividendRound()].value;
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

    // 抽奖获胜者
    function lotteryWinner(uint256 idx) external view returns (address) {
        return _lotteryWinner[idx];
    }

    // 累计贡献值
    function totalContribute() external view returns (uint256){
        return _gState.totalContributes;
    }

    // 累计有效贡献值
    function totalValidCont() external view returns (uint256){
        if(_gCondition.minIndex > 0) {
            return _gState.totalContributes - _treeList[_gCondition.minIndex - 1].totalCont;
        }
        return _gState.totalContributes;
    }

    // 返回用户所有的树，树里包含了树种信息，前端处理以提高效率
    function treeOfAll(address account) external view returns (Tree[] memory) {
        TreeInfo[] memory ut = _userTrees[account];
        Tree[] memory tl = new Tree[](ut.length);       
        for(uint i = 0; i < ut.length; ++i) {
            tl[i] = (_treeList[ut[i].treeIndex]);
        }
        return tl;
    }

    // 返回用户所有的树，树里包含了树种信息，前端处理以提高效率
    function treeOf(address account) external view returns (Tree[] memory) {
        TreeInfo[] memory ut = _userTrees[account];
        Tree[] memory tl = new Tree[](ut.length);
        uint256 j = 0;  
        for(uint i = 0; i < ut.length; ++i) {
            if(ut[i].treeIndex >= _gCondition.minIndex) {
                tl[j] = (_treeList[ut[i].treeIndex]);
                ++j;
            }
        }
        Tree[] memory rtl = new Tree[](j);
        for(uint i = 0; i < j; ++i) {
            rtl[i] = tl[i];
        }
        return rtl;
    }

    // 用户未领取的分红
    function dividendOf(address account) external view returns (uint256){
        TreeInfo[] storage ut =  _userTrees[account];
        uint256 uLen = ut.length;
        if (uLen == 0) {
            return 0;
        }
        Income memory uIncome = _userIncome[account];
        uint256 dRound = uIncome.dividendRound;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentRound = _gCondition.dividendRound;

        for(; dRound < currentRound; ++dRound) {
            DividendCheck memory dc = _dividendCheck[dRound];
            if (dc.value > 0) {
                uint256 minIndexCheck = dc.minIndex;
                uint256 maxIndexCheck = dc.treeIndex;
                uint256 cont = 0;
                while(minIndex < uLen && ut[minIndex].treeIndex < minIndexCheck) {
                    ++minIndex;
                }
                for(uint256 i = uLen - 1; true; --i) {
                    if(ut[i].treeIndex <= maxIndexCheck) {
                        cont = ut[i].totalCont;
                        if (minIndex > 0) {
                            cont -= ut[minIndex - 1].totalCont;
                        }
                        break;
                    }
                    if (i == 0) {
                        break;   
                    }
                }
                sum += dc.value * cont / dc.sumCont;
            }
        }
        return sum;
    }

    // 用户未领取的奖池
    function poolOf(address account) external view returns (uint256) {
        uint256 amount = _userIncome[account].bonus;
        return amount;
    }

    // 用户未领取的推荐奖励
    function refOf(address account) external view returns (uint256){
        return _userIncome[account].ref;
    }

    // 激活用户
    function activate(address superUser) external {
        require(_super[superUser] != address(0), "Super not activated");
        require(_super[msg.sender] == address(0), "Already activated");
        _userIncome[msg.sender].dividendRound = uint32(_getDividendRound());
        _super[msg.sender] = superUser;
    }

    // 购买背景
    function buyBg(uint256 index) external activated started {
        require(index < _bgs.length, "Bg index error");
        // require(_haveBg(msg.sender, index) == false, "Already have bg");
        usdt.transferFrom(msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) external activated started {
        require(num > 0, "Must greater than zero");
        uint256 tIndex = _gCondition.treeNum;
        uint256 day = _getDay();
        uint256 cont = _treeCont(index) * num;
        if (day >= 10) {
            _updateTime(cont);
        }
        if (day < 30) {
            require(_dailyTreeNum[day][msg.sender] + cont <= day + 2, "Up to limit!");
            _dailyTreeNum[day][msg.sender] += cont;
            if (day < 9) {
                require(_gState.totalContributes + cont <= (day + 4) * (day + 1) * 25, "No amount left!");
            } else if(day < 10) {
                require(_gState.totalContributes + cont <= 3300, "No amount left!");
            }
        }
        
        if (_gState.totalContributes <= 60000 && _userTrees[msg.sender].length == 0) {
            require(cont > 1, "At least buy 2!");
        }

        uint256 price = _treePrice(index) * num;
        usdt.transferFrom(msg.sender, address(this), price);
        
        uint256 direct = price * 10 / 100;
        address superUser = _super[msg.sender];
        if (_userTrees[superUser].length > 0) {
            _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
            emit Direct(msg.sender, superUser, direct);
        } else {
            _gState.community += uint64(direct);
        } 

        direct >>= 1;
        superUser = _super[superUser];
        if (_userTrees[superUser].length > 0) {
            _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
            emit InDirect(msg.sender, superUser, direct);
        } else {
            _gState.community += uint64(direct);
        }

        //update trees
        uint256 totalCont = _gState.totalContributes + cont;
        _gState.totalContributes = uint64(totalCont);
        _treeList[tIndex] = Tree(uint8(index), uint48(block.timestamp), uint32(num), uint32(cont), uint64(totalCont), uint64(price / cont));
        _treeOwners[tIndex] = msg.sender;

        uint256 idx = _getDividendRound();
        _dividendCheck[idx] = DividendCheck(uint32(tIndex), 0, uint64(_dividendCheck[idx].value + price * 40 / 100), 0, uint64(totalCont));
        idx = _getRound();
        _lotteryCheck[idx] = CheckPoint(uint64(tIndex), uint64(_gCondition.minIndex), uint128(_lotteryCheck[idx].value + price * 5 / 100));

         // add users  tree
        TreeInfo[] storage ut = _userTrees[msg.sender];
        totalCont = cont; //user total cont
        if(ut.length > 0) {
            totalCont += ut[ut.length-1].totalCont;
        }
        ut.push(TreeInfo(uint64(tIndex), uint64(cont), uint128(totalCont)));

        _gState.bonus += uint64(price * 16 / 100);
        _gState.ecology += uint64(price * 9 / 100);
        _gState.community += uint64(price * 15 / 100);
        _gCondition.treeNum = uint32(tIndex + 1);

        emit BuyTree(msg.sender, price);
    }

    function _getDay() private view returns (uint256) {
        return (block.timestamp + 28800) / 86400 - _gCondition.dayOffset;
    }

    function getDay() external view returns (uint256) {
        return _getDay();
    }

    function _getRound() private view returns (uint256) {
        return block.timestamp / 7200;
    }

    function getRound() external view returns (uint256) {
        return _getRound();
    }

    // 求分红轮数 改为了30分钟一轮，上线前修改
    function _getDividendRound() private view returns (uint256) {
        return (block.timestamp + 25200) / 21600;
    }

    function getDividendRound() external view returns (uint256) {
        return _getDividendRound();
    }

    // 提取分红
    function dividendTake() external returns (uint256) {
        Income storage uIncome = _userIncome[msg.sender];
        uint256 dRound = uIncome.dividendRound;
        uint256 minIndex = uIncome.minIndex;
        uint256 sum = 0;
        uint256 currentRound = _gCondition.dividendRound;
        TreeInfo[] storage ut =  _userTrees[msg.sender];
        uint256 uLen = ut.length;
        if (uLen == 0) {
            return 0;
        }
        for(; dRound < currentRound; ++dRound) {
            DividendCheck memory dc = _dividendCheck[dRound];
            if (dc.value > 0) {
                uint256 minIndexCheck = dc.minIndex;
                uint256 maxIndexCheck = dc.treeIndex;
                uint256 cont = 0;
                while(minIndex < uLen && ut[minIndex].treeIndex < minIndexCheck) {
                    ++minIndex;
                }
                for(uint256 i = uLen - 1; true; --i) {
                    if (ut[i].treeIndex <= maxIndexCheck) {
                        cont = ut[i].totalCont;
                        if (minIndex > 0) {
                            cont -= ut[minIndex - 1].totalCont;
                        }
                        break;
                    }
                    if (i == 0) {
                        break;
                    }
                }
                sum += dc.value * cont / dc.sumCont;
            }
        }
        if (sum > 0) {
            usdt.transfer(msg.sender, sum);
        }
        uIncome.dividendRound = uint32(currentRound);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
        return minIndex;
    }

    // 提取分红
    function dividendTakeRound(uint256 currentRound, uint256 gMinIndex, uint256 gMaxIndex) external returns (uint256) {
        Income storage uIncome = _userIncome[msg.sender];
        uint256 dRound = uIncome.dividendRound;
        uint256 minIndex = uIncome.minIndex;
        if(gMinIndex != 0) {
            minIndex = gMinIndex;  
        }
        uint256 sum = 0;
        TreeInfo[] storage ut =  _userTrees[msg.sender];
        uint256 uLen = ut.length;
        if (uLen == 0) {
            return 0;
        }
        if (gMaxIndex != 0 && gMaxIndex < uLen) {
            uLen = gMaxIndex;
        }
        for(; dRound < currentRound; ++dRound) {
            DividendCheck memory dc = _dividendCheck[dRound];
            if (dc.value > 0) {
                uint256 minIndexCheck = dc.minIndex;
                uint256 maxIndexCheck = dc.treeIndex;
                uint256 cont = 0;
                while(minIndex < uLen && ut[minIndex].treeIndex < minIndexCheck) {
                    ++minIndex;
                }
                for(uint256 i = uLen - 1; true; --i) {
                    if(ut[i].treeIndex <= maxIndexCheck) {
                        cont = ut[i].totalCont;
                        if (minIndex > 0) {
                            cont -= ut[minIndex - 1].totalCont;
                        }
                        break;
                    }
                    if (i == 0) {
                        break;
                    }
                }
                sum += dc.value * cont / dc.sumCont;
            }
        }
        if (sum > 0) {
            usdt.transfer(msg.sender, sum);
        }
        uIncome.dividendRound = uint32(currentRound);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
        return minIndex;
    }

    // 新增：提取推荐奖励，降低购买树苗的收费，合并转账，降低转账手续费
    function refTake() external {
        uint256 amount = _userIncome[msg.sender].ref;
        require(amount > 0, "No remain ref");
        usdt.transfer(msg.sender, amount);
        _userIncome[msg.sender].ref = 0;
        emit RefTake(msg.sender, amount);
    }

    // 提取奖池收益
     function poolTake() external {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        uint256 amount = _userIncome[msg.sender].bonus;
        require(amount > 0, "No remain bonus!");
        usdt.transfer(msg.sender, amount);
        _userIncome[msg.sender].bonus = 0;
        emit PoolTake(msg.sender, amount);
    }

    function addBg(uint256 _price, string memory _url) external onlyAdmin {
        _bgs.push(BackGround(uint128(_bgs.length), uint128(_price), _url));
    }
    
    // 抽奖
    function lottery() external onlyAdmin started {
        uint256 lotteryRound = _gCondition.lotteryRound;
        require(_getRound() > lotteryRound, "It is not time yet!!");
        if (_lotteryCheck[lotteryRound].value > 0) {
            uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
            bytes32 requestId = _rollDice(seed, address(this));
            _requests[requestId] = Request(3, 1, uint128(lotteryRound));
        } else {
            _lotteryCheck[lotteryRound].treeIndex = _lotteryCheck[lotteryRound - 1].treeIndex;
            _gCondition.lotteryRound += 1;
        }
    }

    function ecologyTake(address account) external onlyAdmin {
        if (_gState.ecology > 0) {
            usdt.transfer(account, _gState.ecology);
            _gState.ecology = 0;
        }
    }

    function communityTake(address account) external onlyAdmin {
        if (_gState.community > 0) {
            usdt.transfer(account, _gState.community);
            _gState.community = 0;
        }
    }

    function remainTake(address account, uint256 amount) external onlyAdmin {
        require((_gCondition.flag & 4) == 4, "It is not released!!");
        uint256 timePass = block.timestamp - _gCondition.timestamp;
        require(timePass > 31536000, "It is not time!");
        usdt.transfer(account, amount);
    }

    function dividend() external onlyAdmin {
        uint256 dividendRound = _gCondition.dividendRound;
        require(_getDividendRound() > dividendRound, "It is not time yet!!");
        DividendCheck storage dCheck = _dividendCheck[dividendRound];
        uint256 dValue = dCheck.value;
        if (dValue > 0) {
            uint256 maxIndex = dCheck.treeIndex;
            uint256 sumCont = dCheck.sumCont;
            uint256 minIndex = _gCondition.minIndex;
            uint256 minDividendRound = _gCondition.minDividendRound;
            if (minIndex > 0) {
                sumCont -= _treeList[minIndex - 1].totalCont;
            }
            uint256 totalShare = dValue / sumCont + _dividendCheck[dividendRound - 1].totalShare;

            dCheck.minIndex = uint32(minIndex);
            dCheck.totalShare = uint32(totalShare);
            dCheck.sumCont = uint32(sumCont);

            // update minDividendRound
            uint256 minShare = _dividendCheck[minDividendRound - 1].totalShare;

            for(; minDividendRound < dividendRound; ++minDividendRound) {
                DividendCheck memory dc = _dividendCheck[minDividendRound];
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
            _gCondition.minDividendRound = uint24(minDividendRound);
            _gCondition.dividendRound += 1;
            emit DoDividend(dividendRound, minIndex, minDividendRound, dValue);
        } else {
            dCheck.sumCont = _dividendCheck[dividendRound - 1].sumCont;
            dCheck.treeIndex = _dividendCheck[dividendRound - 1].treeIndex;
            dCheck.totalShare = _dividendCheck[dividendRound - 1].totalShare;
            _gCondition.dividendRound += 1;
            emit DoDividend(dividendRound, _gCondition.minIndex,  _gCondition.minDividendRound, 0);
        }
    }

    function poolRelease() external onlyAdmin {
        require(_ifEnd(), "It is not time yet!!");
        require((_gCondition.flag & 4) == 0, "It is released!!");
        uint256 reward1 = _gState.bonus * 70 / 100;
        uint256 reward2 = _gState.bonus * 20 / 100;
        uint256 secondContribute = Math.min(50, _gState.totalContributes - 1);
        uint256 leftCont = secondContribute;
        if (reward1 > 0) {
            uint256 idx = _gCondition.treeNum - 1;
            Tree memory t = _treeList[idx];
            address user = _treeOwners[idx];
            _userIncome[user].bonus += uint64(reward1);
            if (t.cont > 1) {
                uint256 cont = Math.min(t.cont-1, 50);
                uint256 b = reward2 * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
            }
            emit ReleasePool(user, _userIncome[user].bonus);
            while(leftCont > 0) {
                idx -= 1;
                t = _treeList[idx];
                user = _treeOwners[idx];
                uint256 cont = Math.min(t.cont, leftCont);
                uint256 b = reward2 * cont / secondContribute;
                _userIncome[user].bonus += uint64(b);
                leftCont -= cont;
            }
            _gState.community += uint64(_gState.bonus - reward1 - reward2);
            _gState.bonus = 0;
        }
        _gCondition.flag ^= 4; //released
    }

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
                begin = (begin + 25200) / 86400 * 86400 - 3600;
            }
            if(_isSleep(end)) {
                end = (end + 25200) / 86400 * 86400 - 25200;
            }
            if(begin >= end) {
                return 0;
            } else {
                return (end - begin) - (end - begin) / 86400 * 21600;
            }

        }
    }
    
    // private 消耗gas更少
    function _ifEnd() private view returns (bool) {
        uint256 day = _getDay();
        if (day < 10) {
            return false;
        }
        uint256 dura = _timeGap(_gCondition.timestamp, block.timestamp);
        return dura >= _gCondition.remainTime;
    }

    function minValidTree() external view returns (uint256) {
        return _gCondition.minIndex;
    }

    // 返回当前总共可购买的贡献值
    function remainTotalCont() external view returns (uint256) {
        uint256 day = _getDay();
        if (day < 9) {
            return (day + 4) * (day + 1) * 25 - _gState.totalContributes;
        } else if(day < 10) {
            return 3300 - _gState.totalContributes;
        } else {
            return 100000000000000;
        }
    }

    // 返回账号可购买的贡献值
    function remainUserCont(address account) external view returns (uint256) {
        uint256 day = _getDay();
        if (day < 30) {
            return day + 2 - _dailyTreeNum[day][account];
        } else {
            return 100000000000000;
        }
    }

    function userTotalCont(address account) external view returns (uint256) {
        if (_userTrees[account].length > 0) {
            return _userTrees[account][_userTrees[account].length - 1].totalCont;
        } else {
            return 0;
        }
    }

    function ifEnd() external view returns (bool){
        return _ifEnd();
    }

    function _getLimit() private view returns (uint256) {
        uint256 totalCont = _gState.totalContributes;
        if (totalCont > 20000) {
            return 86400;
        } else {
            return 172800;
        }
    }
}