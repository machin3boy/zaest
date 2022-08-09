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
    mapping (address => mapping (address => mapping (string => string[4]))) public dataUpdateRequests;
    mapping (address => mapping (address => mapping (string => uint))) public dataUpdateRequestTimeLimits;
 
    //permissions verifiers have for specific update functionality
    mapping (address => mapping (string => bool)) public updateFunctionPermissions;

    //encrypted requests to verify ownership of user data
    mapping (address => mapping (address => mapping (string => string[2]))) public dataProofRequests;
    //encrypted user proofs of ownership submitted to the smart contract
    mapping (address => mapping (address => mapping (string => string[3]))) public userProofSmartContract;
    //encrypted user proofs of ownership submitted to IPFS
    mapping (address => mapping (address => mapping (string => string[4]))) public userProofIPFS;

    //valid registered verifiers
    mapping (address => bool) registeredVerifiers;

    //verifiers place their requests for users to update data through this function
    function placeDataUpdateRequest(address userPBK, string memory nonce, string memory encryptedRequest, 
                                    string memory encryptedKey, string memory hashedData, 
                                    string memory hashedRequest, uint timelimit) public {
        require(registeredVerifiers[msg.sender], "You must be a registered verifier to submit requests to update data");
        require(timelimit >= 10, "Verifiers must allow for at least ten seconds to onboard data");
        dataUpdateRequests[msg.sender][userPBK][nonce][0] = encryptedRequest;
        dataUpdateRequests[msg.sender][userPBK][nonce][1] = encryptedKey;
        dataUpdateRequests[msg.sender][userPBK][nonce][2] = hashedData;
        dataUpdateRequests[msg.sender][userPBK][nonce][3] = hashedRequest;
        dataUpdateRequestTimeLimits[msg.sender][userPBK][nonce] = block.timestamp + timelimit;
    }

    //verifiers place their requests for users to prove ownership of data through this function
    function placeDataProofRequest(address userPBK, string memory nonce, string memory encryptedRequest, 
                                    string memory transactionHash) public {
        require(registeredVerifiers[msg.sender], "You must be a registered verifier to submit requests to prove ownership of data");
        dataProofRequests[msg.sender][userPBK][nonce][0] = encryptedRequest;
        dataProofRequests[msg.sender][userPBK][nonce][1] = transactionHash;
    } 


}
