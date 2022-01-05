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
        uint16 currentDay; // 分红天数
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

    GameCondition private _gCondition = GameCondition(1, 0, 0, 0, 0, 0, 86400, 0, 0, 0, 0);
    GameState private _gState = GameState(0, 0, 0, 0, 0);

    mapping(uint256 => DividendCheck) private _dividendCheck;
    mapping(uint256 => CheckPoint) private _lotteryCheck;
    mapping(uint256 => CheckPoint) private _magicCheck;
    mapping(address => Income) private _userIncome;
    mapping(address => TreeInfo[]) private _userTrees;
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
    TRC20Interface internal usdt;
    address private _first;
    address private _nft;
    uint256 private _tokenId = 1;

    bytes32 private s_keyHash;
    uint256 private s_fee;
    

    constructor(address _usdt, address _f, address _n, address vrfCoordinator, address win, address winkMid, bytes32 keyHashValue, uint256 feeValue)
    VRFConsumerBase(vrfCoordinator, win, winkMid){
        _admins[msg.sender] = 1;
        usdt = TRC20Interface(_usdt);
        _first = _f;
        _nft = _n;
        s_keyHash = keyHashValue;
        s_fee = feeValue;
        _super[_f] = _f;
        // 数据迁移，盲盒中奖记录
        initAddTree(address(uint160(uint256(0x4189DAA0B2EC6C67A4204A0358258A6EA1DAEDFF50))), 0, 1, 158000000);
        initAddTree(address(uint160(uint256(0x41346669BB6AFD7CF09372FEF10715D6C9CA0D81FE))), 1, 1, 158000000);
        initAddTree(address(uint160(uint256(0x410CAD25F64FC050E87A7C88095F87F082DF8E5B11))), 2, 1, 158000000);
        initAddTree(address(uint160(uint256(0x41CEE9843831A57C39982A2381F686560B44613802))), 3, 1, 158000000);
        _gState.totalContributes = 4;
        _gCondition.treeNum = 4;
        // 推荐关系
        _super[address(uint160(uint256(0x41549d30c47c0b0fd5777438cae648d75d70955ad1)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x4105e3fadfdedaefe0bc15352d7e876ffc12325bdf)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41a8bf57a3e7cb28b0c17e998b9ba975db4a1e38d2)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41337a85a12041712260bae256904cebbfae9dfe42)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x419423065602c92f7d5b3d03bcd4de817fe8b66d4b)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41e94e07cc3c7e22767a77f7e3082a83b536557f7c)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x415e8134061a89aa8d774924ea7b152e5fb23965d4)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x41784544ab17bad1d94053ad37bbc35afa46e9a696)))]=address(uint160(uint256(0x4175261d059c119730e65e7d6c93fe01fc2a4a4641)));
        _super[address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)))]=address(uint160(uint256(0x41549d30c47c0b0fd5777438cae648d75d70955ad1)));
        _super[address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)))]=address(uint160(uint256(0x41a8bf57a3e7cb28b0c17e998b9ba975db4a1e38d2)));
        _super[address(uint160(uint256(0x4124d603aba7b5d61c0a0e1e7107ef939eae80dcce)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x4168fb73ab0400ef3119392b6692b305a56dc3d030)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x4109e40564adb31327a4624d8427ee1c6b01a0b8bf)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x417a65e3e956984677015513c289e6652fda2cb413)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41d1e33a2c82db53c1bbb9bc1986dcf88cbd3d9345)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x412f265d12fc345fd2cff5045ae2ebcbd48c86e1fd)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41e74b53b04c1056e5f4fb2025dda494c1d810cd28)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41971d5e407e710943f96cee2d36e941b42d352dbb)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x418195d0e4a1f8e6654396c6015ebb4c36962d7c20)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41fe4083148a0bdf8443a11d472d899847a47a5a84)))]=address(uint160(uint256(0x41c33ac5c4559f544cc963329cf33906f74e65c6c7)));
        _super[address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41a720bb3fb8179ce8744beffe9332a7ec09bde76c)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41cf98b7bba1d93abb894ac3e94b771d2909e6056e)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x41ac7dc7af5af2b0bc820a31210737efce8a37c64f)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x410cad25f64fc050e87a7c88095f87f082df8e5b11)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x4121563c735ee233e6cb05b3150b7412e84bb2659f)))]=address(uint160(uint256(0x416abecc0287650f5e251f30e07e4f8eb4d9973ba6)));
        _super[address(uint160(uint256(0x4172be2cc88b48511d859e6700d3211dc61707342e)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x413b7e31fcfea9bdc73657066201e9deef609cabae)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x41f81be89a86b7c0b596ff9b61d60d7a5036bdbd12)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x416618a1a2cda289e8dc45d16dffa1ac2fc0ba6b9d)))]=address(uint160(uint256(0x41f7181748a71c1efb861b15ee91c1712fb54f831d)));
        _super[address(uint160(uint256(0x4137d0bbb93f30b7461ee3cf69c7702b3bca2658eb)))]=address(uint160(uint256(0x41337a85a12041712260bae256904cebbfae9dfe42)));
        _super[address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4129ab83fbdf0b45d3e88e6772aa3527e1d0d5ce5d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x41173a4e64ebad3c7256d22c441f983faf029893be)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x410a75c4a0ab905bc5547dfadfe02be707cdf9db45)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4142d5b6ef60601b5883f5489c2802b08799d2c6da)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x416256f727ffbdbedc1e202a1457ca83911125a09d)))]=address(uint160(uint256(0x41aab5052bcfbfac6b9155111f0a04a8fdbd3e393a)));
        _super[address(uint160(uint256(0x4111720c907ba0517d206ab1455076cf0166f4eb96)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x41f7c878d118f6cb54626b9e1248ec762d31415c04)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x4129648db101318b6cff6c9d3757a17936f0879590)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x4197441dff87cb100f77a37cbb54ce4f9c084868f4)))]=address(uint160(uint256(0x410ca6b712ee6353b7d5d51e762b35f07577e4ba8c)));
        _super[address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4151fbc6cf507720873f120d639ef909f19b2cd209)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41567592d338f5e9fdae924c7053f714f2b74e1325)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41a596df15e649581f81f985794118022b8df4a402)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4107b43c019a0963fdb2042deeb5116233d8657707)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4118df0c8c0864cf1c11405bfc83b27b210890b7c2)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4143053f5dbf25a26ce3e0f983615878297880ff79)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)))]=address(uint160(uint256(0x418c1684b46bf15c18d9e4178a34b63e45ccca6f92)));
        _super[address(uint160(uint256(0x41e5c7d8ab7dbc48a30219d021ef36cee127124edc)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x415ee8854b2d68fc805283d9278767dedbfbd97397)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x41500fe72173f7b42fdbd93ead6b23a0fe72ac079d)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x418d3af534f7ab5a68385eb4d2fd66e6eeb4dd8ad3)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x41e5e07ed93998dc07267712f6c8ee975f5d9c6114)))]=address(uint160(uint256(0x41dbad55b36b1c02163da2f02063dd01dcb0c39ce1)));
        _super[address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41da0cbcc99628121c0df3294f75b3b25642228003)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x413207f5338c157393d9f119bce51c464e4e522e6f)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x4145ea2ae8c4e80e67493a2048cfa748f52a1ed59a)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41b676bae6ce42ab0dbdb0e959e36f9e52ee60dd78)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x414c1f6ca23ce0c295e227493ff87db1de06206233)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41adf09ee93dd1ba7d1514f24cdd6ac2c6cba56386)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41df2f72999afe6b75d1681bfe11ef91bc2243c2a7)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x417bfaf7c4176692ac3894732d2dbbb638b979655b)))]=address(uint160(uint256(0x41aa1bbe4dfe73f9e3adc5ed6a43bd0971cc872ba4)));
        _super[address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x41c19e4694d8753e1d751a977212c9cec02a5758f4)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x4115bc6a9f2e69c5283df21bc1ba046de4543ff8ad)))]=address(uint160(uint256(0x415c756ff3910054c5a3b3d5f73d54efff0a169a47)));
        _super[address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)))]=address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)));
        _super[address(uint160(uint256(0x4157dc9457843a3f1ebbd9b9c3de9ac9cdddbb7798)))]=address(uint160(uint256(0x414633e381b027b5b3aae48d9aa929c2f8d42d5c6d)));
        _super[address(uint160(uint256(0x41abeeed6bb6fb2b326cc346a41e0957b677797d53)))]=address(uint160(uint256(0x41a720bb3fb8179ce8744beffe9332a7ec09bde76c)));
        _super[address(uint160(uint256(0x41fe7e11b818ee027c86c401301e726353d7892d90)))]=address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)));
        _super[address(uint160(uint256(0x41bf0ab828b782e1e3e7b5d0156b6936a422a29098)))]=address(uint160(uint256(0x410660db1ec145908edd083922e140be009a2f078f)));
        _super[address(uint160(uint256(0x411fdc31d675afd448ebbd3adfb92677e2db122528)))]=address(uint160(uint256(0x41173a4e64ebad3c7256d22c441f983faf029893be)));
        _super[address(uint160(uint256(0x4119614991185da0afaf9537fb472c8efffd890431)))]=address(uint160(uint256(0x41e5c7d8ab7dbc48a30219d021ef36cee127124edc)));
        _super[address(uint160(uint256(0x4135809f0eb38252717699b3a45704f39517e317ec)))]=address(uint160(uint256(0x41cf98b7bba1d93abb894ac3e94b771d2909e6056e)));
        _super[address(uint160(uint256(0x4189daa0b2ec6c67a4204a0358258a6ea1daedff50)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x410f4825e58bfa2a8954170b75b86f127aabebc38b)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41fe28f338da67acb950987625d83a7582754216d6)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41e1f571ed7b63e44de72eb90720906b2baae94ea8)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x416142581ba277c9f07c8d8b4eb4511de963cd31fd)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41a89ccdaa58ee554cc95953d4e508cb03d98ff247)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41baf463f0151295de117d13b5fcadcef7f165d582)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x415dc1734cb33552c413ce8e20c9e0512c25d7c68c)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)))]=address(uint160(uint256(0x414b5b7e2b7279d718fec41dfa65f90c86f1a4400d)));
        _super[address(uint160(uint256(0x418273db80c2a0030d79db39eeb0a5ee1333f7dc11)))]=address(uint160(uint256(0x4189daa0b2ec6c67a4204a0358258a6ea1daedff50)));
        _super[address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)))]=address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)));
        _super[address(uint160(uint256(0x41d029da0832580cc8ec15bc421053e1e9ad910228)))]=address(uint160(uint256(0x41e9e807b4931158e2440b67830740f3b34428a2c0)));
        _super[address(uint160(uint256(0x41039ab281a8c27f995d2afb16b274c7d9f81fec6d)))]=address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)));
        _super[address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)))]=address(uint160(uint256(0x41065f2f493703fe862d786e7fb6d4743d2156231e)));
        _super[address(uint160(uint256(0x414357e4ca4a717fa7ba569f1c07e707b6e00e7e87)))]=address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)));
        _super[address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)))]=address(uint160(uint256(0x41175810fcab3244685cd5058b6d30351a708cf353)));
        _super[address(uint160(uint256(0x411c7da51d63b5fcf48c32dd443389116344f5ee4d)))]=address(uint160(uint256(0x410f4825e58bfa2a8954170b75b86f127aabebc38b)));
        _super[address(uint160(uint256(0x41894fb3b02f23aa70cef1db6bf84b96304f152efb)))]=address(uint160(uint256(0x4151fbc6cf507720873f120d639ef909f19b2cd209)));
        _super[address(uint160(uint256(0x4113c9f720f5a1bbced0e6be4409b252bab81a1aa7)))]=address(uint160(uint256(0x41894fb3b02f23aa70cef1db6bf84b96304f152efb)));
        _super[address(uint160(uint256(0x4150d911618988d64e67e0777e4800b029b755097c)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x41352c1973e25b7fd8d66488c3c8eccf09f1acf1d8)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x417c99871fd0b9f7168e8a00f1247afdceb2bb2ea5)))]=address(uint160(uint256(0x41a9072d671af660196d990e9920116da169daa239)));
        _super[address(uint160(uint256(0x41412f6d2a314d8513c859edd71ba2ed63e8c41d08)))]=address(uint160(uint256(0x411c7da51d63b5fcf48c32dd443389116344f5ee4d)));
        _super[address(uint160(uint256(0x41f57d8920e5fa49ea543122ab1a2682ee202e855b)))]=address(uint160(uint256(0x41fe7e11b818ee027c86c401301e726353d7892d90)));
        _super[address(uint160(uint256(0x417ebdc74bae5fbd70f446c45ac47afa1ed533b15d)))]=address(uint160(uint256(0x413207f5338c157393d9f119bce51c464e4e522e6f)));
        _super[address(uint160(uint256(0x412fb1551a89f9061044d5d88aee3637f1f5eca12c)))]=address(uint160(uint256(0x41c19e4694d8753e1d751a977212c9cec02a5758f4)));
        _super[address(uint160(uint256(0x4125156545f67aa2d1b375e0d3c3b96db45fbcc320)))]=address(uint160(uint256(0x416142581ba277c9f07c8d8b4eb4511de963cd31fd)));
        _super[address(uint160(uint256(0x419e11f2072af805162339dc01431d22fac59e00a2)))]=address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)));
        _super[address(uint160(uint256(0x418b5ef2af68f6bf2e71acfe8ef313214011130bd8)))]=address(uint160(uint256(0x41e404e5f7a46eb6b0e0fe8266a272e3fa2535e35c)));
        _super[address(uint160(uint256(0x41b25f75d8fa068655a62a01455841b35d934ca533)))]=address(uint160(uint256(0x4135809f0eb38252717699b3a45704f39517e317ec)));
        _super[address(uint160(uint256(0x411837990dd2f82810e9a211ced2228d8942066b54)))]=address(uint160(uint256(0x419e11f2072af805162339dc01431d22fac59e00a2)));
        _super[address(uint160(uint256(0x41ef33fcfe5cd1a7be38d24072a76630bdb0fbd721)))]=address(uint160(uint256(0x41ac7dc7af5af2b0bc820a31210737efce8a37c64f)));
        _super[address(uint160(uint256(0x412dd0f5d4903fddb603cb6c341bd104e5175a951f)))]=address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)));
        _super[address(uint160(uint256(0x41346669bb6afd7cf09372fef10715d6c9ca0d81fe)))]=address(uint160(uint256(0x41ab46af6e3c6fba5814983a64f49b0c5b89601056)));
        _super[address(uint160(uint256(0x419845526498da5eb08f9c6dc63ef3c4799d0b284d)))]=address(uint160(uint256(0x41baf463f0151295de117d13b5fcadcef7f165d582)));
        _super[address(uint160(uint256(0x4126a3685ccb4f77c548297ca819b3156ee12acfca)))]=address(uint160(uint256(0x419845526498da5eb08f9c6dc63ef3c4799d0b284d)));
        _super[address(uint160(uint256(0x418ef28542e3ed0bf8066ec6fead6d4975c24d8589)))]=address(uint160(uint256(0x41784544ab17bad1d94053ad37bbc35afa46e9a696)));
        _super[address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41e9c02e87fef2b727618047e1dcb0bd61fa60af78)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x4187f206bcda42a4a5183280a6b740a04ee91f8844)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x4113d73065b25e5472f3eca2e349080b52824cf434)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41f4a33dda7e5ca8b569880c5c417755e169d95a77)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41eab783a940d4a18fb86bdcde2aab54e800238115)))]=address(uint160(uint256(0x417bf53d59a62a48c8f58a118ffefe6bd390cddc75)));
        _super[address(uint160(uint256(0x41e7a4c7d5c732f411971b81c969cff6145a6c89c6)))]=address(uint160(uint256(0x417a65e3e956984677015513c289e6652fda2cb413)));
        _super[address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)))]=address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)));
        _super[address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)))]=address(uint160(uint256(0x4106763cc3fb68b5e4e08c7a48b4e9c6de8a45786a)));
        _super[address(uint160(uint256(0x4151d8413603240b7c85531b771c3c0faa236e8104)))]=address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)));
        _super[address(uint160(uint256(0x416d2edd0156155d34544660424309bc0f298e8557)))]=address(uint160(uint256(0x413ffd7990c3168c189b47c8549660d9c40eba63c5)));
        _super[address(uint160(uint256(0x4192aa2e0f36bb2e30a7cb20112ee64db4a584ef49)))]=address(uint160(uint256(0x4126a3685ccb4f77c548297ca819b3156ee12acfca)));
        _super[address(uint160(uint256(0x417506f5169eb8ffa30991d9390518907e470a3c16)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x419b1178d57879de425e3c8b4f18619cbbfbe0d607)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x415b745a7cddd3ed78976382bd0ea73dccc979c05b)))]=address(uint160(uint256(0x413348d84e1cd7eda95e6d109729c93df9681dd98e)));
        _super[address(uint160(uint256(0x41acf859f122f7a3585c761a2f3ab9b768893db804)))]=address(uint160(uint256(0x411fdc31d675afd448ebbd3adfb92677e2db122528)));
        _super[address(uint160(uint256(0x4110e624ebb451c83099763c745b1a5b362d2929b8)))]=address(uint160(uint256(0x41acf859f122f7a3585c761a2f3ab9b768893db804)));
        _super[address(uint160(uint256(0x41fcb38cae41643aab9c5437c8395ac45c1d774ec3)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x41f477cc57e6d0a47d5641d40e1013dd2ea0b5c141)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x41868026465f3150c4bb0c30f47ffe7c2661be46b7)))]=address(uint160(uint256(0x41af63b43f1445296aac3ab27d5ea9f667b01716e4)));
        _super[address(uint160(uint256(0x4173596ada43a75360b34e4be18654ec5c3f0bf049)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x41cee9843831a57c39982a2381f686560b44613802)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x415ec62c6a4816c30fa33b79952403e65987cc4704)))]=address(uint160(uint256(0x4102cba6d57e487dea0fc946aa544ae9d47389488f)));
        _super[address(uint160(uint256(0x41cdb6c3ca7448f2d727a096f783bb5870635cd293)))]=address(uint160(uint256(0x410cad25f64fc050e87a7c88095f87f082df8e5b11)));
        _super[address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)))]=address(uint160(uint256(0x4197441dff87cb100f77a37cbb54ce4f9c084868f4)));
        _super[address(uint160(uint256(0x41d0581124c99bf944654b709f16e042c463d4c9b3)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41bdbea2421189b6e90ed945286d357ab67792da86)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x412e04d720b33343e04238ac90db946f6a700f3b33)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41f18a0138280c5f38a1b5a5a26118eeea2ebca1f6)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x417aa2473927e5fc8f68013c7804c3104834a15190)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x4131676d2eeda264bc64aea136e226859511589409)))]=address(uint160(uint256(0x41ae50ab835e21772d4e8cd1fac4bad05a99f19514)));
        _super[address(uint160(uint256(0x41a6efd2604e2bf73c263582231225c5edfb78b514)))]=address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)));
        _super[address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)))]=address(uint160(uint256(0x411eaf66d36e5d34827a334cc4b5528ac691f76bbd)));
        _super[address(uint160(uint256(0x41570beb3559dfe952ae86fbd102a38efa9f674d2a)))]=address(uint160(uint256(0x41a6efd2604e2bf73c263582231225c5edfb78b514)));
        _super[address(uint160(uint256(0x41525b39c7ab4b600f7dc1f82b4ca25ebd12134c47)))]=address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)));
        _super[address(uint160(uint256(0x410c4821fd2f88267e6010d7accb24187bd6abe12e)))]=address(uint160(uint256(0x411620bf806fa9f8253ca14beb1439370e541f4d6b)));
        _super[address(uint160(uint256(0x41fb9e28b2fae6fcde5af0d9502d9c28b267f87a53)))]=address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)));
        _super[address(uint160(uint256(0x416d8a98edd0ac1330890a658142c48c764241cd5d)))]=address(uint160(uint256(0x416b4d417084f2cc1716bd369eb83bc0087b1262f3)));
        _super[address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x4139164db44f38c284bb74e57872120d29b8218a51)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x4104caa1f25303515bfe58024bf21d0319665d7603)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)))]=address(uint160(uint256(0x4127ca7f87eae933807d32a74557b75fd4285e403f)));
        _super[address(uint160(uint256(0x411701d3199ef291513fb17e3fa459943211ac6ef8)))]=address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)));
        _super[address(uint160(uint256(0x41bea78e7943f20ba361eba2d1959f91d4903a61c1)))]=address(uint160(uint256(0x41dc149f096e9c8e97e720d6cf65638fe8e4b8f3f7)));
        _super[address(uint160(uint256(0x413187bca83ea5b6e004815587563f32f20ad7570a)))]=address(uint160(uint256(0x419b1178d57879de425e3c8b4f18619cbbfbe0d607)));
        _super[address(uint160(uint256(0x414b34e3387365a6d206bd856962f8490de6d78fcd)))]=address(uint160(uint256(0x413187bca83ea5b6e004815587563f32f20ad7570a)));
        _super[address(uint160(uint256(0x413cc19ffcfcd546955de7de6e55820f8b16441766)))]=address(uint160(uint256(0x416618a1a2cda289e8dc45d16dffa1ac2fc0ba6b9d)));
        _super[address(uint160(uint256(0x41483d6a02f3402198bbc74cf4969578a76e2e8149)))]=address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)));
        _super[address(uint160(uint256(0x41d17f544e3138452ee34db8d8cea3a5eed2562794)))]=address(uint160(uint256(0x41c21215171413eb7c0f81331a3d5fb8c326cd5f75)));
        _super[address(uint160(uint256(0x41291422d26444dafb1f0e2f2d87621aadc32e9f2e)))]=address(uint160(uint256(0x41525b39c7ab4b600f7dc1f82b4ca25ebd12134c47)));
        _super[address(uint160(uint256(0x416fe6aa087400bc8750b9b198d5452eedd54708df)))]=address(uint160(uint256(0x41291422d26444dafb1f0e2f2d87621aadc32e9f2e)));
        _super[address(uint160(uint256(0x41aa595192d7ac0148678d0f11d934de8c190aea53)))]=address(uint160(uint256(0x41abeeed6bb6fb2b326cc346a41e0957b677797d53)));
        _super[address(uint160(uint256(0x41046e82c213e91aa82e584e4785c1c33ada0cfceb)))]=address(uint160(uint256(0x410c4821fd2f88267e6010d7accb24187bd6abe12e)));
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
    event GenMaigic(address user);
    event GenNFT(address user);

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

    function initAddTree(address user, uint256 tIndex, uint256 num, uint256 price) internal {
        _treeList[tIndex] = Tree(0, 0, 0, 0, 1640013803, uint32(num), uint32(num), uint64(num), uint64(price / num));
        _treeOwners[tIndex] = user;
        _userTrees[user].push(TreeInfo(uint64(tIndex), uint64(num), uint64(num)));
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
                    emit GenMaigic(_treeOwners[index]);
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
                emit GenNFT(_treeOwners[tIndex]);
            }
            _gCondition.currentNFT += 1;
            r.valid = 0;
        } else if(r.requestType == 3){
            // 抽奖
            require(_gCondition.currentRound == r.value, "Duplicated!");
            CheckPoint memory lCheck = _lotteryCheck[r.value];
            uint256 index = _getRandTree(randomness, lCheck.minIndex, lCheck.treeIndex);
            address user = _treeOwners[index];
            usdt.transfer(user, lCheck.value);
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

    function unprocessRound() external view returns (uint256) {
        return _getRound() - _gCondition.currentRound;
    }

    function unprocessDividend() external view returns (uint256) {
        return _getDay() - _gCondition.currentDay;
    }

    function lotteryInfo(uint256 _round) external view returns (uint256) {
        return _lotteryCheck[_round].value;
    }

    function dividendInfo(uint256 _day) external view returns (uint256) {
        return _dividendCheck[_day].value;
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

    // 神奇果树信息
    function magicTreeInfo(uint256 idx) external view returns (uint256) {
        return _magicTrees[idx];
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
        return _super[account] != address(0);
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

    // 激活用户
    function activate(address superUser) external {
        require(_super[superUser] != address(0), "Super not activated");
        require(_super[msg.sender] == address(0), "Already activated");
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
        usdt.transferFrom(msg.sender, _first, _bgs[index].price);
        _userBgs[msg.sender].push(index);
    }

    // 购买树苗
    function buyTree(uint256 index, uint256 num) external activated started {
        require(num > 0, "Must greater than zero");
        uint256 tIndex = _gCondition.treeNum;
        uint256 timeGap = _timeGap(_gState.timestamp, block.timestamp);
        require(timeGap < _gCondition.remainTime, "Time is over!");
        uint256 price = _treePrice(index) * num;
        usdt.transferFrom(msg.sender, address(this), price);
        
        uint256 direct = price * 10 / 100;
        address superUser = _super[msg.sender];
        _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(direct);
        emit Direct(msg.sender, superUser, direct);
        uint256 indirect = price * 5 / 100;
        superUser = _super[superUser];
        _userIncome[superUser].ref = _userIncome[superUser].ref + uint64(indirect);
        emit InDirect(msg.sender, superUser, indirect);

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
    function dividendTake() external activated started returns (uint256) {
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
            usdt.transfer(msg.sender, sum);
        }
        uIncome.dividendDay = uint32(currentDay);
        uIncome.minIndex = uint32(minIndex);
        emit DividendTake(msg.sender, sum);
        return minIndex;
    }

    // 新增：提取推荐奖励，降低购买树苗的收费，合并转账，降低转账手续费
    function refTake() external activated started {
        uint256 amount = _userIncome[msg.sender].ref;
        require(amount > 0, "No remain ref");
        usdt.transfer(msg.sender, amount);
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
        usdt.transfer(msg.sender, amount);
        _userIncome[msg.sender].bonus = 0;
        emit PoolTake(msg.sender, amount);
    }

    // 购买盲盒
    function buyBox() external activated {
        require(_userBox[msg.sender] == 0, "Only once");
        require((_gCondition.flag & 1) == 1, "Activity end");
        usdt.transferFrom(msg.sender, _first, 5000000);
        _userBox[msg.sender] = block.timestamp;
        _boxUsers.push(msg.sender);
    }

    // ---
    function openBox() external onlyAdmin {
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(4, 1, 0);
        _gCondition.flag ^= 1; //preBuy = 0
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
    }
    
    // 抽取NFT
    function genNFT() external onlyAdmin {
        uint256 nftCount = _magicTrees.length / 20;
        require(_gCondition.currentNFT < nftCount, "It is not time yet!!");
        uint256 seed = uint256(keccak256(abi.encodePacked(gasleft(), _gState.ecology, _gState.community, blockhash(block.number - 1), block.timestamp)));
        bytes32 requestId = _rollDice(seed, address(this));
        _requests[requestId] = Request(2, 1, uint128(_gCondition.currentNFT));
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
        uint256 timePass = block.timestamp - _gState.timestamp;
        require(timePass > 31536000, "It is not time!");
        usdt.transfer(account, amount);
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
    function _ifEnd() private view returns (bool){
        uint256 dura = _timeGap(_gState.timestamp, block.timestamp);
        return dura >= _gCondition.remainTime;
    }

    function minValidTree() external view returns (uint256) {
        return _gCondition.minIndex;
    }

    function userTotalCont(address account) external view returns (uint256) {
        return _userTrees[account][_userTrees[account].length - 1].totalCont;
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

    function setNftAddress(address nft) external onlyAdmin {
        _nft = nft;
    }
}