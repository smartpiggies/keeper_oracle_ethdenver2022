// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.7;

//import "@chainlink/contracts/src/v0.7/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OracleKeeper {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function kill()
        public
    {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}
