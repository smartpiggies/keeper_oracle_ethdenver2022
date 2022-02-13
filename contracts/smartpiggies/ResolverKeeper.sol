/**
 *  Submission for EthDenver 20222 Live hacking participation Event
 *  Implement a chainlink keeper design pattern into the SmartPiggies
 *  bi-lateral risk transfer instrument platform.
 *
 *  This resolver will be called on creation of a new piggy to
 *  register a future price callback, where by a keeper job
 *  will return a price of the underlying at time of expiry
 */
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 contract ResolverKeeper {
     address owner;
     address SmartPiggies;
     address OracleKeeper;

     bytes32 constant TX_SUCCESS = bytes32(0x0000000000000000000000000000000000000000000000000000000000000001);
     uint256 public resolution;
     bytes32 public requestedId;
     uint256 public returnedData;

     struct Request {
         address requester;
         address funder;
         uint256 tokenId;
         uint8 requestType;
     }

     mapping(bytes32 => Request) public requests;

     constructor(address _SmartPiggies, address _OracleKeeper, uint256 _resolution)
     {
         SmartPiggies = _SmartPiggies;
         OracleKeeper = _OracleKeeper;
         resolution = _resolution;
         owner = msg.sender;
     }

     modifier onlyOwner()
     {
         require(msg.sender == owner, "Caller is not Owner.");
         _;
     }

     modifier onlyPiggies()
     {
         require(msg.sender == SmartPiggies, "Caller is not SmartPiggies.");
         _;
     }

     function register
     (
         address _funder,
         uint256 _oracleFee,
         uint256 _tokenId,
         uint256 _expiry,
         uint8 _requestType
     )
      public
      onlyPiggies
      returns (bool)
     {
         _oracleFee; // throw away value, maintains method signature for SmartPiggies

         // generate a unique request id
         bytes32 requestId = keccak256(abi.encodePacked(_funder,_tokenId,_expiry));

         bytes memory payload = abi.encodeWithSignature(
             "registerDataCall(bytes32,uint256,bytes4)",
             requestId,
             _expiry,
             this.getPriceCallback.selector
         );

         (bool registered, bytes memory result) = address(OracleKeeper).call(payload);
         bytes32 txCheck = abi.decode(result, (bytes32));
         require(registered && txCheck == TX_SUCCESS, "register data call failed.");

         requests[requestId] = Request({
           requester: msg.sender,
           funder: _funder,
           tokenId: _tokenId,
           requestType: _requestType
           });

         return true;
     }

     function fetchData(
         address _funder,
         uint256 _oracleFee,
         uint256 _tokenId,
         uint256 _expiry,
         uint8 _requestType
     )
         public
         onlyPiggies
         returns (bool)
     {
         _oracleFee; // throw away value, maintains method signature for SmartPiggies
         _requestType;

         // generate a unique request id
         bytes32 requestId = keccak256(abi.encodePacked(_funder,_tokenId,_expiry));

         bytes memory payload = abi.encodeWithSignature(
             "fulfillDataCall(bytes32,uint256,bytes4)",
             requestId,
             _expiry,
             this.getPriceCallback.selector
         );

         (bool registered, bytes memory result) = address(OracleKeeper).call(payload);
         bytes32 txCheck = abi.decode(result, (bytes32));
         require(registered && txCheck == TX_SUCCESS, "register data call failed.");
         //(bool success, ) = address(OracleKeeper).call(payload);
         //success;
         return true;
     }

     function getPriceCallback(bytes32 _requestId, uint256 _data, bytes memory _signature)
         public
         returns (bool)
     {
         // maintain signature compatibility
         _signature;
         require(msg.sender == OracleKeeper, "Caller is not the oracle keeper");

         requestedId = _requestId;
         returnedData = _data;

         bytes memory payload = abi.encodeWithSignature(
             "callback(uint256,uint256,uint8)",
             requests[_requestId].tokenId,
             (_data / resolution),
             requests[_requestId].requestType
         );
         // SmartPiggies callback does not return
         (bool success, ) = address(requests[_requestId].requester).call(payload);
         success; // send this tx regardless
         return true;
     }

     function updateResolution(uint256 _newResolution)
         public
         onlyOwner
         returns (bool)
     {
         resolution = _newResolution;
         return true;
     }

     function getSmartPiggies()
         public
         view
         returns (address)
     {
         return SmartPiggies;
     }

     function getOracle()
         public
         view
         returns (address)
     {
         return OracleKeeper;
     }

     function kill()
         public
         onlyOwner
     {
         selfdestruct(payable(owner));
     }
 } 
