// SPDX-License-Identifier: MIT
/**
 *  Submission for EthDenver 20222 Live hacking participation Event
 *  Implement a chainlink keeper design pattern into the SmartPiggies
 *  bi-lateral risk transfer instrument platform.
 *
 *  This resolver will be called on creation of a new piggy to
 *  register a future price callback, where by a keeper job
 *  will return a price of the underlying at time of expiry
 */
pragma solidity ^0.8.7;

contract ResolverKeeper {

    address public owner;
    address SmartPiggies;
    address OracleKeeper;

    constructor() {
        owner = msg.sender;
    }

    struct Request {
        address requester;
        address funder;
        uint256 tokenId;
        uint8 requestType;
    }

    constructor(address _SmartPiggies, address _okeeper)
        public
    {
        SmartPiggies = _SmartPiggies;
        OracleKeeper = _okeeper;
        owner = msg.sender;
    }

    function register()
     public
     returns (bool)
    {
      require(msg.sender == SmartPiggies, "Caller is not SmartPiggies.");
      return true;
    }

    function fetchData()
      public
      returns (bool)
    {
        require(msg.sender == SmartPiggies, "Caller is not SmartPiggies.");
        return true;
    }

    function getPriceCallback()
      public
      returns (bool)
    {
      return true;
    }

    function kill()
        public
    {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}
