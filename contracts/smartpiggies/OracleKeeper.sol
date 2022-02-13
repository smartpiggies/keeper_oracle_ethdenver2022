/**
 *  Submission for EthDenver 20222 Live hacking participation Event
 *  Implement a chainlink keeper design pattern into the SmartPiggies
 *  bi-lateral risk transfer instrument platform.
 *
 *  This Oracle Proxy will by a resolver when a new piggy is created.
 *  The proxy will keep track of all requested callbacks,
 *  during the checkUpkeep phase, requests with met expiry conditions
 *  will be forwarded to the performUpkeep phase to retrieve a price
 *  and return the price back to the SmartPiggies contract.
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "@chainlink/contracts/src/v0.7/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Owned {
    address public owner;
    constructor(address _owner)
    {
        owner = _owner;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
}

/**
 *  Chainlink price addresses
 *  ETHUSD 0x0715A7794a1dc8e42615F059dD6e406A6594651A
 *  BTCUSD 0x007A22900a3B98143368Bd5906f8E17e9867581b
 *  MATICUSD 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
 */
abstract contract UsingLookUp is Owned {
    mapping(string => address) public lookups;

    function setLookup(string memory _asset, address _address)
        public
        onlyOwner
        returns (bool)
    {
        lookups[_asset] = _address;
        return true;
    }

}

contract OracleKeeper is UsingLookUp {
    bytes32 constant TX_SUCCESS = bytes32(0x0000000000000000000000000000000000000000000000000000000000000001);
    uint256 constant capacity = 200;

    uint256 head = 0;
    uint256 tail = 0;
    address public lastAsset;
    struct Request {
        address requester;
        bytes32 requestId;
        uint256 expiry;
        bytes4 callback;
    }

    struct Job {
        bytes32 requestId;
        uint256 expiry;
    }

    mapping(bytes32 => Request) public requests;
    mapping(address => string) public assets;
    mapping(address => bool) public resolvers;

    Job[capacity] jobs;

    constructor()
        Owned(msg.sender)
    {

    }

    modifier onlyKnown()
    {
        // only known resolvers
        require(resolvers[msg.sender], "resolver is not recognized");
        _;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(string memory _asset) public view returns (int) {
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(lookups[_asset]);
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        roundID;
        price;
        startedAt;
        timeStamp;
        answeredInRound;
        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */)
        external
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        // performed off-chain to determine if performUpkeep is to be executed
        // We don't use the checkData in this example.
        // The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // We highly recommend revalidating the upkeep in the performUpkeep function
        // We don't use the performData in this example.
        // The performData is generated by the Keeper's call to your checkUpkeep function
    }

    function registerDataCall(bytes32 _requestId, uint256 _expiry, bytes4 _callback)
        public
        onlyKnown
        returns (bool)
    {

        // record requestId
        requests[_requestId] = Request ({
            requester: msg.sender,
            requestId: _requestId,
            expiry: _expiry,
            callback: _callback
        });

        // increase head
        head = head + 1 % capacity;

        // update jobs buffer
        jobs[head] = Job ({
            requestId: _requestId,
            expiry: _expiry
        });

        return true;
    }

    function fulfillDataCall(bytes32 _requestId, uint256 _expiry, bytes4 _callback)
        public
        onlyKnown
        returns (bool)
    {
        // for signature continuity
        _expiry;
        _callback;
        // retrieve request
        Request storage r = requests[_requestId];
        int256 price = getLatestPrice(assets[msg.sender]);
        bytes memory signature = "signature";
        bytes memory payload = abi.encodeWithSelector(r.callback, _requestId, uint256(price), signature);
        (bool success, bytes memory result) = address(r.requester).call(payload);
        bytes32 txCheck = abi.decode(result, (bytes32));
        require(success && txCheck == TX_SUCCESS, "callback to resolver failed");

        // clean up jobs buffer
        uint256 index = 0;
        for(uint256 i = 0; i < capacity; i++)
        {
            if(jobs[i+tail%capacity].requestId == _requestId)
            {
                index = i;
                break;
            }
        }
        // when index of removal is located
        // clean up the buffer
        for(uint256 i = 0; i < capacity; i++)
        {
            if(index == tail)
            {
                delete jobs[index];
                tail = (tail + 1) % capacity;
                break;
            }
            if(index == 0)
            {
                jobs[index] = jobs[capacity-1];
                index = capacity - 1;
            }
            else
            {
                jobs[index] = jobs[index-1];
                index = index - 1;
            }

        }

        return true;
    }

    function updateResolver(address _resolver, string memory _asset)
        public
        onlyOwner
        returns (bool)
    {
        assets[_resolver] = _asset;
        if(!resolvers[_resolver]) resolvers[_resolver] = true;
        return true;
    }

    function kill()
        public
        onlyOwner
    {
        selfdestruct(payable(owner));
    }
}
