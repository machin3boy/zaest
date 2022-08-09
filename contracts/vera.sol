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

import * as OnboardingAES from "./onboarding_aes.sol";
import * as OnboardingHashes from "./onboarding_hashes.sol";
import * as OnboardingIPFS from "./onboarding_ipfs.sol";
import * as OwnershipHashes from "./ownership_hashes.sol";
import * as OwnershipIPFS from "./ownership_ipfs.sol";

contract Vera {

    OnboardingAES.Verifier public onboardAES = new OnboardingAES.Verifier();
    OnboardingHashes.Verifier public onboardHashes = new OnboardingHashes.Verifier();
    OnboardingIPFS.Verifier public onboardIPFS = new OnboardingIPFS.Verifier();
    OwnershipHashes.Verifier public ownershipHashes = new OwnershipHashes.Verifier();
    OwnershipIPFS.Verifier public ownershipIPFS = new OwnershipIPFS.Verifier();

    //SHA256 of user-registered symmetric keys
    mapping (address => uint[2]) public userKeychain;
    //encrypted user data housed in the smart contract
    mapping (address => mapping (uint => mapping (uint => uint[6]))) userDataSmartContract;
    //encrypted user data housed on IPFS
    mapping (address => mapping (uint => mapping (uint => uint[6]))) userDataIPFS;

    //encrypted requests to update data from verifiers
    mapping (address => mapping (address => mapping (uint => string[2]))) public dataUpdateRequestsStrVar;
    mapping (address => mapping (address => mapping (uint => uint[5]))) public dataUpdateRequestIntVar;
 
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

/*
on-boarding function implemented as pseudocode:

function(
     private field u,
    private field d', private field up, 
    private field ar, private field v,
    public field o, public field a,
    public field c, public field h_key,
    public field h_ru, public field h_da,
    public field h_dp, public field h_ipfs_d) {
        prove that:
            1. h_key == hash(u)
            2. h_ru == hash(d' ++ up() ++ ar ++ v)
            3. o == hash(v ++ u)
            4. a == encrypt_AES(d', u)
            5. h_da == hash(d' ++ a ++ u)
            6. h_dp == hash(d')
            7. h_ipfs_d == hash(a ++ o ++ c)

    AES: conditions 1, 4, 6
    AES inputs: [0]: aA, [1]: aB, [2]: aC, [3]: aD,
                [4]: h_keyA, [5]: h_keyB, [6]: h_dpA, [7]: h_dpB

    Hashes: conditions 1, 2, 3, 5, 6
    Hashes inputs: [0]: aA,[1]: aB,[2]: aC,[3]: aD, [4]: oA, [5]: oB,
                   [6]: cA,[7]: cB,[8]: cC,[9]: cD, [10]: h_keyA,
                   [11]: h_keyB, [12]: h_ruA, [13]: h_ruB, [14]: h_daA,
                   [15]: h_daB,
    
    IPFS: condition 7
    IPFS inputs: [0]: aA, [1]: aB, [2]: aC, [3]: aD, [4]: oA,
                 [5]: oB, [6]: cA, [7]: cB, [8]: cC, [9]: cD,
                 [10]: h_ipfs_dA, [11]: h_ipfs_dB
}
*/

    function onboardDataSmartContract(
        address PBKVerifier, uint nonce, OnboardingAES.Verifier.Proof memory proofAES, 
        uint[11] memory inputAES, OnboardingHashes.Verifier.Proof memory proofHashes, 
        uint[21] memory inputHashes) public returns (bool) {
        /*
            a. Assert that on-chain hash == h_key computed off-chain provided to smart
            contract by user when onboarding in User Keychain Mapping for PBK
            b. Assert that h_ru == hash submitted in request by public service verifier
            c. Assert that block timestamp <= t_0 + t_limit [verify times are feasible
            when requests are onboarded by verifiers through smart contract] [store t_0 as
            block.timestamp when request is placed into smart contract]
            d. Assert that on-chain hash == h_dp computed off-chain provided to smart
            contract by verifier
        */
        require(inputAES[0] == inputHashes[0] && inputAES[1] == inputHashes[1] &&
                inputAES[2] == inputHashes[2] && inputAES[3] == inputHashes[3] &&
                inputAES[4] == inputHashes[10] && inputAES[5] == inputHashes[11],
                "Proof rejected: diverging parameters submitted to different components");
        require(userKeychain[msg.sender][0] == inputAES[4] && 
                userKeychain[msg.sender][1] == inputAES[5],
                "Invalid private symmetric key provided with proof");
        require(dataUpdateRequestIntVar[PBKVerifier][msg.sender][nonce][0] == inputAES[6] &&
                dataUpdateRequestIntVar[PBKVerifier][msg.sender][nonce][1] == inputAES[7],
                "Invalid hash of cleartext data provided");   
        require(dataUpdateRequestIntVar[PBKVerifier][msg.sender][nonce][2] == inputHashes[12] &&
                dataUpdateRequestIntVar[PBKVerifier][msg.sender][nonce][3] == inputHashes[13],
                "Invalid hash of request onboarded provided");
        if(onboardAES.verifyTx(proofAES, inputAES) && onboardHashes.verifyTx(proofHashes, inputHashes)){
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][0] = inputHashes[0];
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][1] = inputHashes[1];
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][2] = inputHashes[2];
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][3] = inputHashes[3];
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][4] = inputHashes[14];
               userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][5] = inputHashes[15];
               return true;
        } 
        
        return false;
    }

    function onboardDataIPFS(
        address PBKVerifier, uint nonce, 
        OnboardingAES.Verifier.Proof memory proofAES, uint[11] memory inputAES,
        OnboardingHashes.Verifier.Proof memory proofHashes, uint[21] memory inputHashes,
        OnboardingIPFS.Verifier.Proof memory proofIPFS, uint[13] memory inputIPFS) public {
    require(inputIPFS[0] == inputHashes[0] && inputIPFS[1] == inputHashes[1] &&
        inputIPFS[2] == inputHashes[2] && inputIPFS[3] == inputHashes[3] &&
        inputIPFS[4] == inputHashes[4] && inputIPFS[5] == inputIPFS[5] &&
        inputIPFS[6] == inputHashes[6] && inputIPFS[7] == inputIPFS[7] &&
        inputIPFS[8] == inputHashes[8] && inputIPFS[9] == inputIPFS[9],
        "Proof rejected: diverging parameters submitted to different components");
    if(onboardIPFS.verifyTx(proofIPFS, inputIPFS) &&
        onboardDataSmartContract(PBKVerifier, nonce, proofAES, inputAES, 
        proofHashes, inputHashes)){
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][0] = inputIPFS[6];
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][1] = inputIPFS[7];
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][2] = inputIPFS[8];
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][3] = inputIPFS[9];
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][4] = inputIPFS[10];
            userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][5] = inputIPFS[11];
        }
    }
}
