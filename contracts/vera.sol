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

    //zk-SNARK verifiers
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
    mapping (address => mapping (address => mapping (uint => uint[2]))) public dataProofRequestsIntVar;

    //encrypted user proofs of ownership submitted to the smart contract
    mapping (address => mapping (address => mapping (uint => string[2]))) public userProofSmartContractStrVar;
    mapping (address => mapping (address => mapping (uint => uint[2]))) public userProofSmartContractIntVar;

    //encrypted user proofs of ownership submitted to IPFS
    mapping (address => mapping (address => mapping (uint => uint[6]))) public userProofIPFS;

    //approved list of verifier
    mapping (address => bool) registeredVerifiers;

    //the permissions verifiers have for specific actions 
    mapping (address => mapping (string => bool)) private verifierPermissions;
    
    //Vera developers' access for privileged operations such as onboarding verifiers 
    mapping (address => bool) private veraDeveloperAccess;

    //checking access for privileged functions only Vera developers are allowed to access
    modifier onlyVera {
        require(veraDeveloperAccess[msg.sender]);
        _;
    }

    //this is a Solidity modifier to prevent standard non-verifier users form being able to call privileged functions
    modifier onlyVerifiers {
        require(registeredVerifiers[msg.sender] == true, 
        "You must be a registered verifier to submit requests to update data");
        _;
    }

    //this function serves as a safeguard for Vera developers/government officials/etc. to be able to change any verifiers' 
    //permissions for a specific field or set of fields
    function changeVerifierPermissions(address verifier, string memory permission, bool newVal) public onlyVera{
        registeredVerifiers[verifier] = true;
        verifierPermissions[verifier][permission] = newVal;
    }

    function revokeVerifier(address verifier) public onlyVera{
        registeredVerifiers[verifier] = false;
    }

    //switching the privilege level for any given Vera developer - for instance to remove a retired Vera dev's access
    function switchDeveloperAccess(address a, bool b) public onlyVera{
        veraDeveloperAccess[a] = b;
    }

    //registering the first Vera developer with the contract constructor as the first privileged user 
    constructor(){
        veraDeveloperAccess[msg.sender] = true;
    }

    //onboarding secondary symmetric keys for users
    function onboardUserkeys(uint h_keyA, uint h_keyB) public{
        userKeychain[msg.sender][0] = h_keyA;
        userKeychain[msg.sender][1] = h_keyB;
    }

    //verifiers place their requests for users to update data through this function
    function placeDataUpdateRequest(address userPBK, uint nonce, string memory encryptedRequest, 
                                    string memory encryptedKey, uint hashOfData0,
                                    uint hashOfData1, uint hashOfRequest0,
                                    uint hashOfRequest1, uint timelimit) public onlyVerifiers{
        require(timelimit >= 10, "Verifiers must allow for at least ten seconds to onboard data");
        dataUpdateRequestsStrVar[msg.sender][userPBK][nonce][0] = encryptedRequest;
        dataUpdateRequestsStrVar[msg.sender][userPBK][nonce][1] = encryptedKey;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][0] = hashOfData0;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][1] = hashOfData1;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][2] = hashOfRequest0;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][3] = hashOfRequest1;
        dataUpdateRequestIntVar[msg.sender][userPBK][nonce][4] = block.timestamp + timelimit;
    }

    //verifiers place their requests for users to prove ownership of data through this function
    function placeDataProofRequest(address userPBK, uint nonce, string memory encryptedRequest, 
                                    uint transactionHash0, uint transactionHash1) public onlyVerifiers{
        dataProofRequestsStrVar[msg.sender][userPBK][nonce] = encryptedRequest;
        dataProofRequestsIntVar[msg.sender][userPBK][nonce][0] = transactionHash0;
        dataProofRequestsIntVar[msg.sender][userPBK][nonce][1] = transactionHash1;
    } 

    /*

        on-boarding function implemented as pseudocode:

        function(

            private field u, private field d',
            private field up, private field ar,
            private field v, public field o,
            public field a,  public field c,
            public field h_key,  public field h_ru,
            public field h_da, public field h_dp,
            public field h_ipfs_d) {

            prove that:

            1. h_key	== hash(u)
            2. h_ru	== hash(d' ++ up() ++ar ++ v)
            3. o		== hash(v ++ u)
            4. a		== encrypt_AES(d', u)
            5. h_da	== hash(d' ++ a ++ u)
            6. h_dp	== hash(d')
            7. h_ipfs_d == hash(a ++ o ++ c)

        }

            AES: conditions 1, 4, 6
            AES inputs: [0]: aA, [1]: aB, [2]: aC, [3]: aD,
                        [4]: h_keyA, [5]: h_keyB, [6]: h_dpA, [7]: h_dpB

            Hashes: conditions 1, 2, 3, 5, 6
            Hashes inputs: [0]: aA,[1]: aB,[2]: aC,[3]: aD, [4]: oA, [5]: oB,
                        [6]: cA,[7]: cB,[8]: cC,[9]: cD, [10]: h_keyA,
                        [11]: h_keyB, [12]: h_ruA, [13]: h_ruB, [14]: h_daA,
                        [15]: h_daB
            
            IPFS: condition 7
            IPFS inputs: [0]: aA, [1]: aB, [2]: aC, [3]: aD, [4]: oA,
                        [5]: oB, [6]: cA, [7]: cB, [8]: cC, [9]: cD,
                        [10]: h_ipfs_dA, [11]: h_ipfs_dB

    */

    //users onboard data into the smart contract through this function
    function onboardDataSmartContract(address PBKVerifier, uint nonce, OnboardingAES.Verifier.Proof memory proofAES, 
                                      uint[9] memory inputAES, OnboardingHashes.Verifier.Proof memory proofHashes, 
                                      uint[17] memory inputHashes) public returns (bool){
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
        require(dataUpdateRequestIntVar[PBKVerifier][msg.sender][nonce][2] < block.timestamp,
        "Onboarding request rejected: time limit exceeded");
        require(inputAES[0] == inputHashes[0] && inputAES[1] == inputHashes[1] &&
        inputAES[2] == inputHashes[2] && inputAES[3] == inputHashes[3] &&
        inputAES[4] == inputHashes[10] && inputAES[5] == inputHashes[11],
        "Proof rejected: diverging parameters submitted to different components");
        require(userKeychain[msg.sender][0] == inputAES[4] && userKeychain[msg.sender][1] == inputAES[5],
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

    //users onboard data into IPFS through this function
    function onboardDataIPFS(address PBKVerifier, uint nonce, OnboardingAES.Verifier.Proof memory proofAES, 
                             uint[9] memory inputAES, OnboardingHashes.Verifier.Proof memory proofHashes, 
                             uint[17] memory inputHashes, OnboardingIPFS.Verifier.Proof memory proofIPFS, 
                             uint[13] memory inputIPFS) public{
        require(inputIPFS[0] == inputHashes[0] && inputIPFS[1] == inputHashes[1] &&
        inputIPFS[2] == inputHashes[2] && inputIPFS[3] == inputHashes[3] &&
        inputIPFS[4] == inputHashes[4] && inputIPFS[5] == inputIPFS[5] &&
        inputIPFS[6] == inputHashes[6] && inputIPFS[7] == inputIPFS[7] &&
        inputIPFS[8] == inputHashes[8] && inputIPFS[9] == inputIPFS[9],
        "Proof rejected: diverging parameters submitted to different components");
        if(onboardIPFS.verifyTx(proofIPFS, inputIPFS) && 
            onboardDataSmartContract(PBKVerifier, nonce, proofAES, inputAES, proofHashes, inputHashes)){
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][0] = inputIPFS[6];
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][1] = inputIPFS[7];
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][2] = inputIPFS[8];
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][3] = inputIPFS[9];
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][4] = inputIPFS[10];
                userDataIPFS[msg.sender][inputIPFS[4]][inputIPFS[5]][5] = inputIPFS[11];
            }
    }

    /*

    proof of ownership function implemented as pseudocode:

        function( private field u, private field v
                public field n, private field d,
                public field o, public field a, 
                public field e_rs, public field c,
                public field h_key, public field h_tx,
                public field h_da, public field h_dn,
                public field h_ipfs_p){

            prove that:

            1. h_key	== hash(u)
            2. h_tx	== hash(v ++ n)
            3. o	== hash(v ++ u)
            4. h_da == hash(d ++ a ++ u)
            5. h_dn == hash(d ++ v ++ n)
            6. h_ipfs_p	== hash(e_rs ++ c)

        }

        Hashes: conditions 1, 2, 3, 5, 5
        Hashes inputs: [0]: aA, [1]: aB, [2]: aC, [3]: aD, [4]: oA
                    [5]: oB, [6]: n,  [7]: h_keyA, [8]: h_keyB,
                    [9]: h_txA, [10]: h_txB, [11]: h_daA,
                    [12]: h_daB, [13]: h_dnA, [14]: h_dnB

        IPFS: condition 6
        IPFS inputs: [0]: e_rsA, [1]: e_rsB, [2]: e_rsC, [3]: e_rsD, [4]: cA, 
                    [5]: cB, [6]: cC, [7]: cD, [8]: h_ipfs_pA, 
                    [9]: h_ipfs_pB

    */

    //users prove ownership of data housed in smart contract through this function
    function proveUserDataSmartContract(address PBKVerifier, uint nonce, OwnershipHashes.Verifier.Proof memory proofHashes, 
                                        uint[16] memory inputHashes, string memory encryptedResponse, 
                                        string memory encryptedEphemeralKey) public returns (bool){
        /*
            a. Assert that on-chain hash == h_key computed off-chain provided to smart
            contract by user when onboarding in User Keychain Mapping for PBK
            b. Assert that on-chain hash == h_tx computed off-chain provided to smart
            contract by public service verifier
            c. Assert that User Data Mapping at (PBK_user) => o => (a, h_da)
        */
        require(userKeychain[msg.sender][0] == inputHashes[7] && userKeychain[msg.sender][1] == inputHashes[8],
        "Invalid private symmetric key provided with proof");
        require(dataProofRequestsIntVar[PBKVerifier][msg.sender][nonce][0] == inputHashes[9] &&
        dataProofRequestsIntVar[PBKVerifier][msg.sender][nonce][0] == inputHashes[10],
        "Transaction hash for user proof provided mismatched request");
        require(userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][0] == inputHashes[0] &&
        userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][1] == inputHashes[1] &&
        userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][2] == inputHashes[2] &&
        userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][3] == inputHashes[3] &&
        userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][4] == inputHashes[11] &&
        userDataSmartContract[msg.sender][inputHashes[4]][inputHashes[5]][5] == inputHashes[12],
        "Mapping at provided obfuscated field does not match provided encrypted data");
        if(ownershipHashes.verifyTx(proofHashes, inputHashes)){
            userProofSmartContractStrVar[PBKVerifier][msg.sender][nonce][0] = encryptedResponse;
            userProofSmartContractStrVar[PBKVerifier][msg.sender][nonce][1] = encryptedEphemeralKey;
            userProofSmartContractIntVar[PBKVerifier][msg.sender][nonce][0] = inputHashes[13];
            userProofSmartContractIntVar[PBKVerifier][msg.sender][nonce][0] = inputHashes[14];
            return true;
        } 
        return false;
    }

    //users prove ownership of data housed on IPFS through this function
    function proveUserDataIPFS(address PBKVerifier, uint nonce, OwnershipHashes.Verifier.Proof memory proofHashes, 
                               uint[16] memory inputHashes, string memory encryptedResponse, 
                               string memory encryptedEphemeralKey, OwnershipIPFS.Verifier.Proof memory proofIPFS, 
                               uint[11] memory inputIPFS) public{                            
        if(proveUserDataSmartContract(PBKVerifier, nonce, proofHashes, inputHashes, 
        encryptedResponse, encryptedEphemeralKey) &&  ownershipIPFS.verifyTx(proofIPFS, inputIPFS)){
            userProofIPFS[PBKVerifier][msg.sender][nonce][0] = inputIPFS[4];
            userProofIPFS[PBKVerifier][msg.sender][nonce][1] = inputIPFS[5];
            userProofIPFS[PBKVerifier][msg.sender][nonce][2] = inputIPFS[6];
            userProofIPFS[PBKVerifier][msg.sender][nonce][3] = inputIPFS[7];
            userProofIPFS[PBKVerifier][msg.sender][nonce][4] = inputIPFS[8];
            userProofIPFS[PBKVerifier][msg.sender][nonce][5] = inputIPFS[9];
        }                    
    }
}

