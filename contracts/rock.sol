// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Context {
    // Empty internal constructor
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
      return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        return msg.data;
    }
}

contract Coin {
    // The keyword "public" makes variables
    // accessible from other contracts
    address public minter;
    mapping (address => uint) public balances;

    // Events allow clients to react to specific
    // contract changes you declare
    event Sent(address from, address to, uint amount);

    // Constructor code is only run when the contract
    // is created
    constructor() {
        minter = msg.sender;
    }

    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    error InsufficientBalance(uint requested, uint available);

    // Sends an amount of existing coins
    // from any caller to an address
    function send(address receiver, uint amount) public {
        if (amount > balances[msg.sender])
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });

        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function preMineSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 value);
}

library SafeMath {

}

library Address {
    function isContract(address account) internal view returns (bool) {
        return false;
    }

    function sendValue(address payable recipient, uint256 amount) internal {

    }
}

library BEP20Impl {

}

contract RockPreSale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    bool public claimReady;
    uint256 private constant _jazzLimit = 100 * 1e18;

    struct PriceRate {
        uint256 nominator;
        uint256 denominator;
    }

    struct ClaimStatus {
        bool jazzHolder;
        bool claimed;
        uint256 jazzAmount;
        uint256 buyAmount;
    }
    mapping (address => ClaimStatus) private _claimStatus;
    uint8 public maxPhase;

    struct IcoBalance {
        uint256 depositAmount;
        uint256 remainAmount;
    }
    IcoBalance icoBalance;

    struct Phase {
        bool  isRunning;
        PriceRate price;
        uint256 endDate;
    }
    mapping (uint8 => Phase) private _phaseList;

    uint8 public currentPhaseNum;
    IBEP20 private _token;
    IBEP20 public aceptableToken;


    modifier swapActive() {
        require(swapLive, "Airdrop must be active");
        _;
    }

    function addBuyerTolist(address _buyer) public onlyOwner returns (bool) {
        return _addBuyerTolist(_buyer);
    }

    function _addBuyerTolist(address _buyer) private returns (bool) {
        require(_buyer != address(0), "Pre-Sale: buyer address is the zero address");
        return EnumerableSet.add(_buyerlist, _buyer);
    }

    function getPhase(uint8 _phaseNum) public view returns (
        bool  isRunning,
        uint256 priceN,
        uint256 priceD,
        uint256 endDate) {
        require (_phaseNum >0 && _phaseNum < 9, "Pre-Sale: Phase number must be small than 9.");
        isRunning = _phaseList[_phaseNum].isRunning;
        priceN = _phaseList[_phaseNum].price.nominator;
        priceD = _phaseList[_phaseNum].price.denominator;
        endDate = _phaseList[_phaseNum].endDate;
    }

    function forwardPhase () public onlyOwner {
        _forwardPhase();
    }

    function _forwardPhase() private icoActive returns(bool)  {
        require (currentPhaseNum <= maxPhase, "ICO is over");

        for (uint8 i = 1; i <= maxPhase; i++) {
            if(now < _phaseList[i].endDate){
                _phaseList[currentPhaseNum].isRunning = false;
                currentPhaseNum = i;
                _phaseList[currentPhaseNum].isRunning = true;
                return true;
            }
        }

        _stopICO();
        return false;
    }
}
