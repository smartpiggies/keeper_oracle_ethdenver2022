/**
 *  Submission for EthDenver 20222 Live hacking participation Event
 *  Implement a chainlink keeper design pattern into the SmartPiggies
 *  bi-lateral risk transfer instrument platform.
 *
 *  This Oracle Proxy will register a price callback when a new piggy is created.
 *  The proxy will keep track of all requested callbacks,
 *  during the checkUpkeep phase, requests with met expiry conditions
 *  will be forwarded to the performUpkeep phase to retrieve a price
 *  and return the price back to the SmartPiggies contract.
 */
// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: Oracles/OracleKeeper.sol


pragma solidity ^0.8.7;

//import "@chainlink/contracts/src/v0.7/KeeperCompatible.sol";


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
 *  Mumbai ==>
 *  ETHUSD 0x0715A7794a1dc8e42615F059dD6e406A6594651A
 *  BTCUSD 0x007A22900a3B98143368Bd5906f8E17e9867581b
 *  MATICUSD 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
 *  Kovan ==>
 *  ETHUSD 0x9326BFA02ADD2366b30bacB125260Af641031331
 *  BTCUSD 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e
 *  TSLAUSD 0xb31357d152638fd1ae0853d24b9Ea81dF29E3EF2
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
    uint256 constant public bufferSize = 200;

    uint256 public head = 0;
    uint256 public tail = 0;
    uint256 public capacity = bufferSize;
    address public requestedAddress;

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

    Job[bufferSize] public jobs;

    constructor()
        Owned(msg.sender)
    { }

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
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // performed off-chain to determine if performUpkeep is to be executed
        // We don't use the checkData in this example.
        // The checkData is defined when the Upkeep was registered.
        uint256 expiry;
        upkeepNeeded = false;
        for(uint256 i = 0; i < bufferSize; i++)
        {
            expiry = jobs[addmod(tail, i, bufferSize)].expiry;
            if(expiry != 0 && expiry < block.timestamp)
            {
                upkeepNeeded = true;
                break;
            }
            if(addmod(tail, i, bufferSize) == head) // if the index meets the head, bail
            {
                break;
            }
        }
        performData = (upkeepNeeded) ? abi.encode(0x01) : abi.encode(0x00);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // We highly recommend revalidating the upkeep in the performUpkeep function
        // We don't use the performData in this example.
        // The performData is generated by the Keeper's call to your checkUpkeep function
        bytes32 id;
        address requester;
        uint256 expiry;
        uint256 index;
        for(uint256 i = 0; i < bufferSize; i++)
        {
            index = addmod(tail, i, bufferSize);
            expiry = jobs[index].expiry;
            if(expiry != 0 && expiry < block.timestamp)
            {
                id = jobs[index].requestId;
                requester = requests[id].requester;
                _processDataCall(id, assets[requester]);
            }
            if(addmod(tail, i, bufferSize) == head) // if the index meets the head, bail
            {
                break;
            }
        }
    }

    function registerDataCall(bytes32 _requestId, uint256 _expiry, bytes4 _callback)
        public
        onlyKnown
        returns (bool)
    {
        require(0 < capacity, "Jobs buffer full");

        // record requestId
        requests[_requestId] = Request ({
            requester: msg.sender,
            requestId: _requestId,
            expiry: _expiry,
            callback: _callback
        });

        // increase head
        head = addmod(head, 1, bufferSize);

        // update jobs buffer
        jobs[head] = Job ({
            requestId: _requestId,
            expiry: _expiry
        });

        capacity -= 1;
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
        _processDataCall(_requestId, assets[msg.sender]);
        return true;
    }

    function _processDataCall(bytes32 _requestId, string memory _asset)
        internal
    {
        // retrieve request
        Request storage r = requests[_requestId];
        requestedAddress = lookups[_asset];
        int256 price = getLatestPrice(_asset);
        bytes memory signature = "signature";
        bytes memory payload = abi.encodeWithSelector(r.callback, _requestId, uint256(price), signature);
        (bool success, bytes memory result) = address(r.requester).call(payload);
        bytes32 txCheck = abi.decode(result, (bytes32));
        require(success && txCheck == TX_SUCCESS, "callback to resolver failed");

        // clean up jobs buffer
        uint256 index = 0;
        for(uint256 i = 0; i < bufferSize; i++)
        {
            index = addmod(tail, i, bufferSize);
            if(jobs[index].requestId == _requestId)
            {
                break;
            }
        }
        // when index of removal is located
        // clean up the buffer
        for(uint256 i = 0; i < bufferSize; i++)
        {
            if(index == tail)
            {
                delete jobs[index];
                tail = addmod(tail, 1, bufferSize);
                break;
            }
            if(index == 0)
            {
                jobs[index] = jobs[bufferSize-1];
                index = bufferSize - 1;
            }
            else
            {
                jobs[index] = jobs[index-1];
                index = index - 1;
            }
        }
        // clear buffer check
        require((capacity += 1) <= bufferSize, "Buffer is empty");
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
