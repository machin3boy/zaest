/*

 /$$    /$$                            
| $$   | $$                            
| $$   | $$ /$$$$$$   /$$$$$$  /$$$$$$ 
|  $$ / $$//$$__  $$ /$$__  $$|____  $$
 \  $$ $$/| $$$$$$$$| $$  \__/ /$$$$$$$
  \  $$$/ | $$_____/| $$      /$$__  $$
   \  $/  |  $$$$$$$| $$     |  $$$$$$$
    \_/    \_______/|__/      \_______/

*/
pragma solidity ^0.8.0;

import * as OnboardingAes from "./onboarding_aes.sol";
import * as OnboardingHashes from "./onboarding_hashes.sol";
import * as OnboardingIPFS from "./onboarding_ipfs.sol";
import * as OwnershipHashes from "./ownership_hashes.sol";
import * as OwnershipIPFS from "./ownership_ipfs.sol";

contract Vera {

    //SHA256 of user-registered symmetric keys
    mapping (address => string) public userKeychain;
    //encrypted user data housed in the smart contract
    mapping (address => mapping (string => string)) userDataSmartContract;
    //encrypted user data housed on IPFS
    mapping (address => mapping (string => string[2])) userDataIPFS;

    //encrypted requests to update data from verifiers
    mapping (address => mapping (address => mapping (uint => string[2]))) public dataUpdateRequestsStrVar;
    mapping (address => mapping (address => mapping (uint => uint[3]))) public dataUpdateRequestIntVar;
 
    //permissions verifiers have for specific update functionality
    mapping (address => mapping (string => bool)) public updateFunctionPermissions;

    //encrypted requests to verify ownership of user data
    mapping (address => mapping (address => mapping (uint => string))) public dataProofRequestsStrVar;
    mapping (address => mapping (address => mapping (uint => uint))) public dataProofRequestsIntVar;
    //encrypted user proofs of ownership submitted to the smart contract
    mapping (address => mapping (address => mapping (uint => string[3]))) public userProofSmartContract;
    //encrypted user proofs of ownership submitted to IPFS
    mapping (address => mapping (address => mapping (uint => string[4]))) public userProofIPFS;

    //valid registered verifiers
    mapping (address => bool) registeredVerifiers;

    //verifiers place their requests for users to update data through this function
    function placeDataUpdateRequest(address userPBK, uint nonce, string memory encryptedRequest, 
                                    string memory encryptedKey, uint hashOfData, 
                                    uint hashOfRequest, uint timelimit) public {
        require(registeredVerifiers[msg.sender], "You must be a registered verifier to submit requests to update data");
        require(timelimit >= 10, "Verifiers must allow for at least ten seconds to onboard data");
        dataUpdateRequestsStrVar[msg.sender][userPBK][nonce][0] = encryptedRequest;
        dataUpdateRequestsStrVar[msg.sender][userPBK][nonce][1] = encryptedKey;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][0] = hashOfData;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][1] = hashOfRequest;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][2] = block.timestamp + timelimit;
    }

    //verifiers place their requests for users to prove ownership of data through this function
    function placeDataProofRequest(address userPBK, uint nonce, string memory encryptedRequest, 
                                    uint transactionHash) public {
        require(registeredVerifiers[msg.sender], "You must be a registered verifier to submit requests to prove ownership of data");
        dataProofRequestsStrVar[msg.sender][userPBK][nonce] = encryptedRequest;
        dataProofRequestsIntVar[msg.sender][userPBK][nonce] = transactionHash;
    } 
}
