<template>
  <div class="flex flex-col bg-stone-900 text-white min-h-screen" > 
    <ParticlesBackground v-if="currentPath!=='#/userpage' &&
                               currentPath!=='#/verifierpage' &&
                               currentPath!=='#/secondarykeys'" />
    <Menu :connectionStatus="connectionStatus" @connect="connectMetamask"/>
   
    <About v-if="currentPath==='#/about'" class="flex grow" />
    
    <SecondaryKeys v-else-if="currentPath==='#/secondarykeys'" class="flex grow"
      @updateSecondaryKeysAES="updateKeysAES" @buttonSecondaryKeysAES="handleAES"
      @updateSecondaryKeysRSA="updateKeysRSA" @buttonSecondaryKeysRSA="handleRSA"
      :props="secondaryKeysCards"
    />
    
    <UserPage v-else-if="currentPath==='#/userpage'" class="flex grow" 
      :active="userActiveRequestCards" :action="userActionCards"
      :decrypted="userProofCards" :submitted="userSubmittedRequests" :account="accountAddress"
      @buttonUserActiveReq="handleUserActive" @buttonUserActionReq="handleUserAction"
      @buttonUserProofReq="handleUserProof"
    />
    
    <VerifierPage v-else-if="currentPath==='#/verifierpage'" class="flex grow"
      :request="verifierRequestCards" :submitted="verifierSubmittedRequests" 
      :received="verifierReceivedProofs" :account="accountAddress"
      @updateOnboardingReq="updateOnboardingReq" @buttonOnboardingReq="handleOnboardingReq"
      @updateOwnershipReq="updateOwnershipReq" @buttonOwnershipReq="handleOwnershipReq"
    />

    <Home v-else /> 

    <el-backtop :right="30" :bottom="30" class="bg-black" />
    <Footer />
  </div>
</template>

<script setup>
import { ref, computed, h } from "vue";
import { ElNotification } from 'element-plus';
import { Web3Storage } from 'web3.storage';

import SimpleCard from "./components/SimpleCard.vue";
import InputsCard from "./components/InputsCard.vue";
import Menu from "./components/Menu.vue";
import ParticlesBackground from "./components/ParticlesBackground.vue";
import InputField from "./components/InputField.vue";
import Home from "./components/Home.vue";
import About from "./components/About.vue";
import UserPage from "./components/UserPage.vue";
import VerifierPage from "./components/VerifierPage.vue";
import SecondaryKeys from "./components/SecondaryKeys.vue";
import Footer from "./components/Footer.vue";

import * as utilFns from "./util";

import Web3 from 'web3';
import axios from 'axios';

const storageClient = new Web3Storage({
  token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDY1Mjg1ZUUwNDBhMUJGYTZkNTRCMTg1NzdFNzc5OGRiM2ExODE0ZDciLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NjExNzM4ODM4NDQsIm5hbWUiOiJ6YWVzdCJ9.UHE2aGUwvYBfYvTD5r9CokI28HIL9YEVD_yn6RTgnn0"
})

const routes = {
  '/': Home,
  '/about': About,
  '/secondarykeys': SecondaryKeys,
  '/userpage': UserPage,
  '/verifierpage': VerifierPage,
}

const currentPath = ref(window.location.hash)

window.addEventListener('hashchange', () => {
  currentPath.value = window.location.hash
})

const currentView = computed(() => {
  return routes[currentPath.value.slice(1) || '/'] || NotFound
})

const url = "http://localhost:3001";
const connectionStatus = ref('Connect Wallet');
const accountAddress = ref('');
const contractAddress = "0x5B3fB9655fab94D5A9491Ed3f8a4620afBA874A5";
const ABI = require('../ABI.json');
let web3;
let zaestContract;

async function connectMetamask(){

  connectionStatus.value = 'processing';
  if (window.ethereum) {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
    accountAddress.value = accounts[0];
    connectionStatus.value = 'wallet connected';
    web3 = new Web3(window.ethereum);
    zaestContract = new web3.eth.Contract(ABI, contractAddress);
  }
  else {
    connectionStatus.value = 'Metamask Required';
  }
}

const secondaryKeysCards = ref([
{
  "title": "AES keys",
  "inputs": {
    "AES key": ""
  },
  "texts": {
    "generated AES key": "",
  },
  "buttons": [
    "generate AES key",
    "use key for dApp",
    "onboard key to smart contract",
  ]
},
{
  "title": "RSA keys",
  "inputs": {
    "RSA public key (PBK)": "",
    "RSA private key (PVK)": "",
  },
  "texts": {
    "generated RSA public key": "",
    "generated RSA private key": "",
  },
  "buttons": [
    "generate RSA keys",
    "use keys for dApp",
    "onboard PBK to smart contract",
  ]
},
]);

const verifierRequestCards = ref([
{
  "title": "new data onboarding request",
  "inputs": {
    "user address": "",
    "field to update": "",
    "new data": "",
    "update operation": "",
    "update arguments": "",
    "time limit": "",
  },
  "texts": {
    "generated ephemeral key": "",
  },
  "buttons": [
    "generate ephemeral key",
    "send request to smart contract",
  ]
},
{
  "title": "new data verification request",
  "inputs": {
    "user address": "",
    "field requested": "",
  },
  "texts": {
  },
  "buttons": [
    "send request to smart contract",
  ]
}]);

const userActionCards = ref([
{
  "title": "select request",
  "texts": {
    "request type": "",
    "requesting verifier": "",
    "nonce": "",
    "request time": "",
    "request expiry time": "",
  },
  "buttons": [
    "decrypt request",
    "ignore request",
  ]
},
{
  "active": "false",
}
])

const userProofCards = ref([
{
  "title": "data onboarding parameters",
  "texts": {
    "field requested": "",
    "new data": "",
    "update operation": "",
    "arguments": "",
    "IPFS CID (optional)": ""
  },
  "buttons": [
    "place data on IPFS (optional)",
    "generate ZKP for smart contract",
    "submit response to smart contract",
    "generate ZKP for smart contract & IPFS",
    "submit response to smart contract & IPFS",
  ],
  "data": {
    "e_ru": "",
    "kPrime": "",
    "h_dp_0": "",
    "h_dp_1": "",
    "h_ru_0": "",
    "h_ru_1": "",
    "tLimit": "",
    "k": "",
    "dPrime": "",
    "updateOp": "",
    "nonce": "",
    "ar": "",
    "v": "",
    "a": "",
    "o": "",
    "c": "ipfshasnotbeeninitializedbutthisisanexampleaddress",
    "verifier": "",
  },
  "active": "false",
},
{
  "title": "data verification parameters",
  "texts": {
    "field requested": "",
    "IPFS CID (optional)": ""
  },
  "buttons": [
    "place data on IPFS (optional)",
    "generate ZKP for smart contract",
    "submit response to smart contract",
    "generate ZKP for smart contract & IPFS",
    "submit response to s.c. & IPFS",
  ],
  "data": {
    "e_rq": "",
    "h_tx_0": "",
    "h_tx_1": "",
    "n": "",
    "nonce": "",
    "v": "v",
    "verifier": "",
    "kPrime": "",
    "e_rs": "",
    "c": "ipfshasnotbeeninitializedbutthisisanexampleaddress",
  },
  "active": "false",
}])

const verifierSubmittedRequests = ref([]);
const verifierReceivedProofs = ref([]);
const userActiveRequestCards = ref([]);
const userSubmittedRequests = ref([]);

const aesKeys = ref([]);
const rsaKeys = ref([]);

const fieldTest = ref('');
const zkSNARKsOnboardingHashes = ref([]);
const zkSNARKsOnboardingAES = ref([]);
const zkSNARKsOnboardingIPFS = ref([]);
const zkSNARKsOwnershipHashes = ref([]);
const zkSNARKsOwnershipIPFS = ref([]);

const updateOnboardingReq = (...args) => {
  verifierRequestCards.value[0].inputs[args[0]] = args[1];
}

const updateOwnershipReq = (...args) => {
  verifierRequestCards.value[1].inputs[args[0]] = args[1];
}

const updateKeysAES = (...args) => {
  secondaryKeysCards.value[0].inputs[args[0]] = args[1];
}

const updateKeysRSA = (...args) => {
  secondaryKeysCards.value[1].inputs[args[0]] = args[1];
}

const handleAES = (...args) => {
  if(args[0]==='generate AES key'){
    secondaryKeysCards.value[0].texts["generated AES key"] = utilFns.oneTimeKey(16); 
  }
  if(args[0]==='use key for dApp'){
    storeAESkey();
    notification("Secondary Keys", "Your AES key was onboarded successfully");
  }
  if(args[0]==='onboard key to smart contract'){
    let key = aesKeys.value.
              filter((x) => x.address === accountAddress.value)
              [0].aesKey;
    let hash = utilFns.hashStr(key);
    let h_keyA = utilFns.hexToBig(hash.substring(0,32));
    let h_keyB = utilFns.hexToBig(hash.substring(32));
    zaestContract.
      methods.
      onboardUserSymmetricKey(h_keyA, h_keyB).
      send({ from: accountAddress.value }, function (err, res) {
        if (err) {
          console.log("An error occured", err)      
          return
        }
        notification("Smart Contract", "SHA256 of AES key placed into the smart contract")
        console.log("Hash of the transaction: " + res)
      })
  }
}

const handleRSA = async (...args) => {
  if(args[0]==='generate RSA keys'){
    const keys =  await axios.get(`${url}/rsaKeys`).then((response) =>
      [response['data'][0].substring(5), response['data'][1].substring(5)]); 
    secondaryKeysCards.value[1].texts["generated RSA private key"] = keys[0];
    secondaryKeysCards.value[1].texts["generated RSA public key"] = keys[1];
  }
  if(args[0]==='use keys for dApp'){
    storeRSAkeys();
    notification("Secondary Keys", "Your RSA keys were onboarded successfully");
  }
  if(args[0]==='onboard PBK to smart contract'){
    let key = rsaKeys.value.
              filter((x) => x.address.toLowerCase() === accountAddress.value.toLowerCase())
              [0].rsaPBK;
    zaestContract.
      methods.
      onboardAsymmetricKey(key).
      send({ from: accountAddress.value }, function (err, res) {
        if (err) {
          console.log("An error occured", err)      
          return
        }
        notification("Smart Contract", "Your PBK has been placed into the smart contract")
        console.log("Hash of the transaction: " + res)
      })
  }      
}

const handleOnboardingReq = async (...args) => {
  if(args[0]==='generate ephemeral key'){
    verifierRequestCards.value[0].texts["generated ephemeral key"] = utilFns.oneTimeKey(16); 
  }
  if(args[0]==='send request to smart contract'){


    let i = verifierRequestCards.value[0].inputs;
    const userAddress = i["user address"];

    let t = verifierRequestCards.value[0].texts;

    let p = rsaKeys.value.
            filter((x) => x.address.toLowerCase() === accountAddress.value.toLowerCase())
            [0].rsaPBK;
    
    const paddedDPrime = i["new data"] + "_".repeat(64-i["new data"].length);
    const paddedUpdate = i["update operation"] + "_".repeat(16-i["update operation"].length);
    const paddedArgs = i["update arguments"] + "_".repeat(16-i["update arguments"].length);
    const paddedVar = i["field to update"] + "_".repeat(32-i["field to update"].length);
    const ru = paddedDPrime + paddedUpdate + paddedArgs + paddedVar;
    const h_dp = utilFns.hashStr(paddedDPrime);
    const h_dp_0 = utilFns.hexToBig(h_dp.substring(0, h_dp.length/2)).toString();
    const h_dp_1 = utilFns.hexToBig(h_dp.substring(h_dp.length/2)).toString(); 
    const h_ru = utilFns.hashStr(ru);
    const h_ru_0 = utilFns.hexToBig(h_ru.substring(0, h_ru.length/2)).toString();
    const h_ru_1 = utilFns.hexToBig(h_ru.substring(h_ru.length/2)).toString();
    const k  = t["generated ephemeral key"].replace(/\s+/g, "");
    const e_ru = await performAES(k, ru, 'encrypt');
    const kPrime = await performRSA(p, k, 'encrypt');
    const n = utilFns.oneTimeKey(16);
    const nonce = utilFns.strToBig(n).toString();
    const tLimit= i["time limit"].toString();

    zaestContract.
      methods.
      placeDataUpdateRequest(
        userAddress,
        nonce,
        e_ru,
        kPrime,
        h_dp_0,
        h_dp_1,
        h_ru_0,
        h_ru_1,
        tLimit
      ).
      send({ from: accountAddress.value }, function (err, res) {
        if (err) {
          console.log("An error occured", err)      
          return
        }
        
        console.log("Hash of the transaction: " + res)

        let d = new Date();
        let e = new Date();
        e.setSeconds(e.getSeconds() + parseInt(tLimit));

        let dateStringD = ("0" + d.getDate()).slice(-2) + "-" + ("0"+(d.getMonth()+1)).slice(-2) + "-" +
        d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
        let dateStringE = ("0" + e.getDate()).slice(-2) + "-" + ("0"+(e.getMonth()+1)).slice(-2) + "-" +
        e.getFullYear() + " " + ("0" + e.getHours()).slice(-2) + ":" + ("0" + e.getMinutes()).slice(-2);

        userActiveRequestCards.value.push({
          "verifier": accountAddress.value,
          "recipient": userAddress.replace(/\s+/g, ""),
          "ignore": "false",
          "title": "request " + n,
          "texts": {
            "request type": "onboard new data",
            "requesting verifier": accountAddress.value,
            "nonce": n,
            "request time": dateStringD,
            "request expiry time": dateStringE,
          },
          "buttons": [
            "select request",
            "ignore request",
          ]
        });

        verifierSubmittedRequests.value.push({
          "verifier": accountAddress.value,
          "title": "request " + n,
          "texts": {
            "request type": "onboard new data",
            "requested account": userAddress,
            "nonce": n,
            "request time": dateStringD,
            "request expiry time": dateStringE,
          },
        })

        notification("Smart Contract", "Data onboarding request submitted to smart contract")
      })
  }
}

const handleOwnershipReq = async (...args) => {

    let v = verifierRequestCards.value[1].inputs["field requested"];
    let userAddress = verifierRequestCards.value[1].inputs["user address"];
    let n = utilFns.oneTimeKey(16); 

    let p = rsaKeys.value.
            filter((x) => x.address.toLowerCase() === accountAddress.value.toLowerCase())
            [0].rsaPBK;
    
    const paddedVar = v + "_".repeat(32-v.length);
    const e_rq = await performRSA(p, paddedVar, 'encrypt');
    const nonce = utilFns.strToBig(n).toString();
    const h_tx = utilFns.hashStr(paddedVar+n);
    const h_tx_0 = utilFns.hexToBig(h_tx.substring(0, h_tx.length/2)).toString();
    const h_tx_1 = utilFns.hexToBig(h_tx.substring(h_tx.length/2)).toString();    

    zaestContract.
      methods.
      placeDataProofRequest(
        userAddress,
        nonce,
        e_rq,
        h_tx_0,
        h_tx_1
      ).
      send({ from: accountAddress.value }, function (err, res) {
        if (err) {
          console.log("An error occured", err)      
          return
        }

        let d = new Date();
        let e = new Date();
        e.setSeconds(e.getSeconds() + 18000);

        let dateStringD = ("0" + d.getDate()).slice(-2) + "-" + ("0"+(d.getMonth()+1)).slice(-2) + "-" +
        d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
        let dateStringE = ("0" + e.getDate()).slice(-2) + "-" + ("0"+(e.getMonth()+1)).slice(-2) + "-" +
        e.getFullYear() + " " + ("0" + e.getHours()).slice(-2) + ":" + ("0" + e.getMinutes()).slice(-2);


        verifierSubmittedRequests.value.push({
          "verifier": accountAddress.value,
          "title": "request " + n,
          "texts": {
            "request type": "proof of ownership",
            "requested account": userAddress,
            "nonce": n,
            "request time": dateStringD,
            "request expiry time": dateStringE,
          },
        })

        userActiveRequestCards.value.push({
          "verifier": accountAddress.value,
          "recipient": userAddress.replace(/\s+/g, ""),
          "ignore": "false",
          "title": "request " + n,
          "texts": {
            "request type": "proof of ownership",
            "requesting verifier": accountAddress.value,
            "nonce": n,
            "request time": dateStringD,
            "request expiry time": dateStringE,
          },
          "buttons": [
            "select request",
            "ignore request",
          ]
        });

        notification("Smart Contract", "Proof of data ownership request submitted to smart contract");
        console.log("Hash of the transaction: " + res);
      })
}

const handleUserActive = async (...args) => {
  if(args[1]==='ignore request'){
    userActiveRequestCards.value[args[0]].ignore = 'true';
  }
  if(args[1]==='select request'){
    let activeCard = userActiveRequestCards.value[args[0]];
    userActionCards.value[1].active = 'true';
    userActionCards.value[0].title = activeCard.title;
    userActionCards.value[0].texts["request type"] = activeCard.texts["request type"];
    userActionCards.value[0].texts["requesting verifier"] = activeCard.verifier;
    userActionCards.value[0].texts["request time"] = activeCard.texts["request time"];  
    userActionCards.value[0].texts["request expiry time"] = activeCard.texts["request expiry time"];
    userActionCards.value[0].texts["nonce"] = activeCard.texts["nonce"];
  }
}

const handleUserAction = async (...args) => {
  if(args[0]==='ignore request'){
    userActionCards.value[1].active = 'false';
    userProofCards.value[0].active = 'false';
    userProofCards.value[1].active = 'false';
  }
  if(args[0]==='decrypt request'){
    const verifierAddress = userActionCards.value[0].texts["requesting verifier"];
    const userAddress = accountAddress.value;
    const n = userActionCards.value[0].texts["nonce"];
    const nonce = utilFns.strToBig(n).toString();
    //onboard new data || proof of ownership
    const requestType = userActionCards.value[0].texts["request type"];

    let RSA_PVK = rsaKeys.value.
              filter((x) => x.address === accountAddress.value)
              [0].rsaPVK;
    let u = aesKeys.value.
              filter((x) => x.address === accountAddress.value)
              [0].aesKey;

    if(requestType === "onboard new data"){
      //data retrieval
      //dataUpdateRequestsStrVar = e_ru, kPrime
      //dataUpdateRequestIntVar = h_dp_0, h_dp_1, h_rq_0, h_rq_1, tlimit
      let e_ru, kPrime, h_dp_0, h_dp_1, h_ru_0, h_ru_1, tLimit;
      await zaestContract.methods.dataUpdateRequestsStrVar(verifierAddress,userAddress,nonce,0).call().then((result)=>{e_ru=result});
      await zaestContract.methods.dataUpdateRequestsStrVar(verifierAddress,userAddress,nonce,1).call().then((result)=>{kPrime=result});
      await zaestContract.methods.dataUpdateRequestIntVar(verifierAddress,userAddress,nonce,0).call().then((result)=>{h_dp_0=result});
      await zaestContract.methods.dataUpdateRequestIntVar(verifierAddress,userAddress,nonce,1).call().then((result)=>{h_dp_1=result});
      await zaestContract.methods.dataUpdateRequestIntVar(verifierAddress,userAddress,nonce,2).call().then((result)=>{h_ru_0=result})
      await zaestContract.methods.dataUpdateRequestIntVar(verifierAddress,userAddress,nonce,3).call().then((result)=>{h_ru_1=result});
      await zaestContract.methods.dataUpdateRequestIntVar(verifierAddress,userAddress,nonce,4).call().then((result)=>{tLimit=result});
      //decryption of retrieved data
      let k = await performRSA(RSA_PVK, kPrime, 'decrypt');
      k = k.replace(/\s+/g, "");
      const ru = await performAES(k, e_ru, 'decrypt');
      const dPrime = ru.substring(0, 64);
      const updateOp = ru.substring(64, 80);
      const ar = ru.substring(80, 96);
      const v = ru.substring(96);

      userProofCards.value[0].texts["field requested"] = v;
      userProofCards.value[0].texts["new data"] = dPrime;
      userProofCards.value[0].texts["update operation"] = updateOp;
      userProofCards.value[0].texts["arguments"] = ar;
      userProofCards.value[0].data["e_ru"] = e_ru;
      userProofCards.value[0].data["kPrime"] = kPrime;
      userProofCards.value[0].data["h_dp_0"] = h_dp_0;
      userProofCards.value[0].data["h_dp_1"] = h_dp_1;
      userProofCards.value[0].data["h_ru_0"] = h_ru_0;
      userProofCards.value[0].data["h_ru_1"] = h_ru_1;
      userProofCards.value[0].data["tLimit"] = tLimit;
      userProofCards.value[0].data["k"] = k;
      userProofCards.value[0].data["dPrime"] = dPrime;
      userProofCards.value[0].data["updateOp"] = updateOp;
      userProofCards.value[0].data["ar"] = ar;
      userProofCards.value[0].data["v"] = v;
      userProofCards.value[0].data["verifier"] = verifierAddress;
      userProofCards.value[0].data["nonce"] = nonce;
      userProofCards.value[0].active = 'true';
    }
    else if(requestType === "proof of ownership"){
      //data retrieval
      //dataProofRequestsStrVar = e_rq
      //dataProofRequestsIntVar = h_tx_0, h_tx_1
      let e_rq;
      let h_tx_0;
      let h_tx_1;
      console.log("parameters:", nonce, verifierAddress, userAddress);
      await zaestContract.methods.dataProofRequestsStrVar(verifierAddress,userAddress,nonce).call().then((result)=>{e_rq=result});
      await zaestContract.methods.dataProofRequestsIntVar(verifierAddress,userAddress,nonce,0).call().then((result)=>{h_tx_0=result});
      await zaestContract.methods.dataProofRequestsIntVar(verifierAddress,userAddress,nonce,1).call().then((result)=>{h_tx_1=result});
      //decryption of retrieved data
      const v = await performRSA(RSA_PVK, e_rq, 'decrypt');
      console.log(v);
      
      userProofCards.value[1].texts["field requested"] = v; 
      userProofCards.value[1].data.e_rq = e_rq;
      userProofCards.value[1].data.h_tx_0 = h_tx_0;
      userProofCards.value[1].data.h_tx_1 = h_tx_1;
      userProofCards.value[1].data.nonce = nonce;
      userProofCards.value[1].data.n = n;
      userProofCards.value[1].data.v = v;
      userProofCards.value[1].data.verifier = verifierAddress;
      userProofCards.value[1].active = 'true';
    }
  }
}

const placeToIPFS = ref(["false", 0]);

const handleUserProof = async (...args) => {
  // index 0: onboarding, index 1: verification
  const i = args[0];
  const button = args[1];
  if(button==='generate ZKP for smart contract'){
    if(i === 0){
      let res = await generateOnboardingProofHashes();
      console.log(res);
      let res2 = await generateOnboardingProofAES();
      console.log(res2);
      notification("ZKP notification", "Your proofs are ready");
    }
    if(i === 1){
      let res = await generateOwnershipProofHashes();
      console.log(res);
      notification("ZKP notification", "Your proofs are ready");
    }
  }
  if(button==='generate ZKP for smart contract & IPFS'){
    if(i===0){
      let res = await generateOnboardingProofHashes();
      console.log(res);
      let res2 = await generateOnboardingProofAES();
      console.log(res2);
      let res3 = await generateOnboardingProofIPFS();
      console.log(res3);
      notification("ZKP notification", "Your proofs are ready");
    }
    if(i===1){
      let res = await generateOwnershipProofHashes();
      console.log(res);
      let res2 = await generateOwnershipProofIPFS();
      console.log(res2);
      notification("ZKP notification", "Your proofs are ready");
    }
  }
  if(button==="place data on IPFS (optional)"){
    notification("IPFS notification", "Your proof/data will be stored on IPFS, select the IPFS options")
    placeToIPFS.value[0] = "true";
    if(i===0)
      placeToIPFS.value[1] = 0;
    else
      placeToIPFS.value[1] = 1; 
  }
  if(button==="submit response to smart contract"){
    let proofOnboardingHashes = zkSNARKsOnboardingHashes.value;
    let proofOnboardingAES = zkSNARKsOnboardingAES.value;
    let proofOnboardingIPFS = zkSNARKsOnboardingIPFS.value;
    let proofOwnershipHashes = zkSNARKsOwnershipHashes.value;
    let proofOwnershipIPFS = zkSNARKsOwnershipIPFS.value;
    if(i === 0){
      let PBKVerifier = userProofCards.value[0].data.verifier;
      let nonce = userProofCards.value[0].data.nonce;
      let proofOnboardingHashesParameters = proofOnboardingHashes[0];
      let proofOnboardingHashesInputs = proofOnboardingHashes[1];  
      let proofOnboardingAESParameters = proofOnboardingAES[0];
      let proofOnboardingAESInputs = proofOnboardingAES[1];
      console.log(PBKVerifier, nonce, proofOnboardingHashesParameters,
                  proofOnboardingHashesInputs, proofOnboardingAESParameters,
                  proofOnboardingAESInputs);
      await zaestContract.
        methods.
        onboardDataSmartContract(PBKVerifier, nonce, proofOnboardingAESParameters,
                                  proofOnboardingAESInputs, proofOnboardingHashesParameters,
                                  proofOnboardingHashesInputs
                                  ).
        send({ from: accountAddress.value }, function (err, res) {
          if (err) {
            console.log("An error occured", err)      
            return
          }
          console.log("Hash of the transaction: " + res)
        });
    }
    if(i === 1){
      let PBKVerifier = userProofCards.value[1].data.verifier;
      let nonce = userProofCards.value[1].data.nonce;
      let e_rs = userProofCards.value[1].data.e_rs;
      let kPrime = userProofCards.value[1].data.kPrime;
      let proofOwnershipHashesParameters = proofOwnershipHashes[0];
      let proofOwnershipHashesInputs = proofOwnershipHashes[1];
      await zaestContract.
        methods.
        proveUserDataSmartContract(PBKVerifier, nonce, proofOwnershipHashesParameters,
                                  proofOwnershipHashesInputs, e_rs,
                                  kPrime
                                  ).
        send({ from: accountAddress.value }, function (err, res) {
          if (err) {
            console.log("An error occured", err)      
            return
          }
          console.log("Hash of the transaction: " + res)
        });
    }
  }
  if(button==="submit response to smart contract & IPFS"){
    let proofOnboardingHashes = zkSNARKsOnboardingHashes.value;
    let proofOnboardingAES = zkSNARKsOnboardingAES.value;
    let proofOnboardingIPFS = zkSNARKsOnboardingIPFS.value;
    let proofOwnershipHashes = zkSNARKsOwnershipHashes.value;
    let proofOwnershipIPFS = zkSNARKsOwnershipIPFS.value;
    if(i === 0){
      let proofOnboardingHashesParameters = proofOnboardingHashes[0];
      let proofOnboardingHashesInputs = proofOnboardingHashes[1];  
      let proofOnboardingAESParameters = proofOnboardingAES[0];
      let proofOnboardingAESInputs = proofOnboardingAES[1];
      let proofOnboardingIPFSParameters = proofOnboardingIPFS[0];
      let proofOnboardingIPFSInputs = proofOnboardingIPFS[1];
      let PBKVerifier = userProofCards.value[0].data.verifier;
      let nonce = userProofCards.value[0].data.nonce;
      
      await zaestContract.
        methods.
        onboardDataIPFS(PBKVerifier, nonce, proofOnboardingAESParameters,
                        proofOnboardingAESInputs, proofOnboardingHashesParameters,
                        proofOnboardingHashesInputs, proofOnboardingIPFSParameters,
                        proofOnboardingIPFSInputs
                        ).
        send({ from: accountAddress.value }, function (err, res) {
          if (err) {
            console.log("An error occured", err)      
            return
          }
          console.log("Hash of the transaction: " + res)
        });
    }
    if(i === 1){
      let proofOwnershipHashesParameters = proofOwnershipHashes[0];
      let proofOwnershipHashesInputs = proofOwnershipHashes[1];
      let proofOwnershipIPFSParameters = proofOwnershipIPFS[0];
      let proofOwnershipIPFSInputs = proofOwnershipIPFS[1];
      let PBKVerifier = userProofCards.value[1].data.verifier;
      let nonce = userProofCards.value[1].data.nonce;
      let e_rs = userProofCards.value[1].data.e_rs;
      let kPrime = userProofCards.value[1].data.kPrime;
      await zaestContract.
        methods.
        proveUserDataIPFS(PBKVerifier, nonce, proofOwnershipHashesParameters,
                            proofOwnershipHashesInputs, e_rs,
                            kPrime, proofOwnershipIPFSParameters,
                            proofOwnershipIPFSInputs
                          ).
        send({ from: accountAddress.value }, function (err, res) {
          if (err) {
            console.log("An error occured", err)      
            return
          }
          console.log("Hash of the transaction: " + res)
        });
    }
  }
}

async function generateOnboardingProofHashes(){
  const d = userProofCards.value[0].data;
  let u = aesKeys.value.
          filter((x) => x.address === accountAddress.value)
          [0].aesKey;
  let a = await performAES(u, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA = a.substring(0,32);
  let aB = a.substring(32,64);
  let aC = a.substring(64,96);
  let aD = a.substring(96, 128);
  let o =  utilFns.hashStr(d.v + u);
  
  userProofCards.value[0].data.a = a;
  userProofCards.value[0].data.o = o;
  let h_da = utilFns.hashHex(utilFns.strToHex(d.dPrime.substring(0, 16)) +
                     utilFns.strToHex(d.dPrime.substring(16, 32)) +
                     utilFns.strToHex(d.dPrime.substring(32, 48)) +
                     utilFns.strToHex(d.dPrime.substring(48)) +
                     a + utilFns.strToHex(u));
  await axios.get(`${url}/zokratesOnboardingHashes`,
    { params: {
      u:  utilFns.strToBig(u),
      dA: utilFns.strToBig(d.dPrime.substring(0, 16)),
      dB: utilFns.strToBig(d.dPrime.substring(16, 32)),
      dC: utilFns.strToBig(d.dPrime.substring(32, 48)),
      dD: utilFns.strToBig(d.dPrime.substring(48)),
      up: utilFns.strToBig(d.updateOp),
      ar: utilFns.strToBig(d.ar),
      vA: utilFns.strToBig(d.v.substring(0, 16)),
      vB: utilFns.strToBig(d.v.substring(16)),
      aA: utilFns.hexToBig(aA),
      aB: utilFns.hexToBig(aB),
      aC: utilFns.hexToBig(aC),
      aD: utilFns.hexToBig(aD),
      oA: utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(0,32)),
      oB: utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(32)),
      h_keyA: utilFns.hexToBig(utilFns.hashStr(u).substring(0, 32)),
      h_keyB: utilFns.hexToBig(utilFns.hashStr(u).substring(32)),
      h_ruA: d.h_ru_0,
      h_ruB: d.h_ru_1,
      h_daA: utilFns.hexToBig(h_da.substring(0, 32)),
      h_daB: utilFns.hexToBig(h_da.substring(32)),
      }
    },
    {
      transformResponse: [data => data]
    }).then((res) => {
      let j = res.data
      zkSNARKsOnboardingHashes.value.push([j.proof.a, j.proof.b, j.proof.c]);
      zkSNARKsOnboardingHashes.value.push(j.inputs);
    });
  return zkSNARKsOnboardingHashes.value;
}

async function generateOnboardingProofIPFS(){
  const d = userProofCards.value[0].data;
  let u = aesKeys.value.
          filter((x) => x.address === accountAddress.value)
          [0].aesKey;
  let a = await performAES(u, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA = a.substring(0,32);
  let aB = a.substring(32,64);
  let aC = a.substring(64,96);
  let aD = a.substring(96, 128);
  let oA =  utilFns.hashStr(d.v + u).substring(0,32);
  let oB =  utilFns.hashStr(d.v + u).substring(32);
  let cA =  d.c.substring(0,16);
  let cB =  d.c.substring(16,32);
  let cC =  d.c.substring(32,48);
  let cD =  d.c.substring(48) + "_".repeat(64-d.c.length);
  let h_ipfs_d = utilFns.hashHex(a + oA + oB + utilFns.strToHex(cA+cB+cC+cD));

  
  if(placeToIPFS.value[0]==="true" && placeToIPFS.value[1]===0){ 
      let d = "value of a: " + aA + aB + aC + aD + ", value of o: " + oA + oB;
      const f = new File([d], 'zaest_onboarding_proof.txt');
      const cid = await storageClient.put([f]);
      userProofCards.value[0].data.c = cid;
      userProofCards.value[0].texts["IPFS CID (optional)"] = cid;
      placeToIPFS.value[0]="false";
  }    

  await axios.get(`${url}/zokratesOnboardingIPFS`,
    { params: {
      aA: utilFns.hexToBig(aA),
      aB: utilFns.hexToBig(aB),
      aC: utilFns.hexToBig(aC),
      aD: utilFns.hexToBig(aD),
      oA: utilFns.hexToBig(oA),
      oB: utilFns.hexToBig(oB),
      cA: utilFns.strToBig(cA),
      cB: utilFns.strToBig(cB),
      cC: utilFns.strToBig(cC),
      cD: utilFns.strToBig(cD),
      h_ipfs_d0: utilFns.hexToBig(h_ipfs_d.substring(0,32)),
      h_ipfs_d1: utilFns.hexToBig(h_ipfs_d.substring(32)),
      }
    },
    {
      transformResponse: [data => data]
    }).then((res) => {
      let j = res.data
      zkSNARKsOnboardingIPFS.value.push([j.proof.a, j.proof.b, j.proof.c]);
      zkSNARKsOnboardingIPFS.value.push(j.inputs); 
    });
  return zkSNARKsOnboardingIPFS.value;
}

async function generateOnboardingProofAES(){

  const d = userProofCards.value[0].data;
  let u = aesKeys.value.
          filter((x) => x.address === accountAddress.value)
          [0].aesKey;  
  let a = await performAES(u, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA = a.substring(0,32);
  let aB = a.substring(32,64);
  let aC = a.substring(64,96);
  let aD = a.substring(96, 128);
  await axios.get(`${url}/zokratesOnboardingAES`,
    { params: {
      u:  utilFns.strToBig(u),
      dA: utilFns.strToBig(d.dPrime.substring(0, 16)),
      dB: utilFns.strToBig(d.dPrime.substring(16, 32)),
      dC: utilFns.strToBig(d.dPrime.substring(32, 48)),
      dD: utilFns.strToBig(d.dPrime.substring(48)),
      aA: utilFns.hexToBig(aA),
      aB: utilFns.hexToBig(aB),
      aC: utilFns.hexToBig(aC),
      aD: utilFns.hexToBig(aD),
      h_keyA: utilFns.hexToBig(utilFns.hashStr(u).substring(0, 32)),
      h_keyB: utilFns.hexToBig(utilFns.hashStr(u).substring(32)),
      h_dpA: utilFns.hexToBig(utilFns.hashStr(d.dPrime).substring(0,32)),
      h_dpB: utilFns.hexToBig(utilFns.hashStr(d.dPrime).substring(32)),
      }
    },
    {
      transformResponse: [data => data]
    }).then((res) => {
      let j = res.data
      zkSNARKsOnboardingAES.value.push([j.proof.a, j.proof.b, j.proof.c]);
      zkSNARKsOnboardingAES.value.push(j.inputs);
    });
  return zkSNARKsOnboardingAES.value;
}

//a browser-side ephemeral key that has to be the same to
//correctly generate the proof for the ownership of the encrypted request
//if IPFS is utilized
const ephemereForOwnership = ref('');
/*
function( private field u, private field v
        public field n, private field d,
        public field o, public field a,  
        public field e_rs, public field c,
        public field h_key, public field h_tx,
        public field h_da, public field h_dn,
        public field h_ipfs_p){
*/
async function generateOwnershipProofHashes(){
  const d = userProofCards.value[1].data;
  const userAddress = accountAddress.value;
  const verifierAddress = d.verifier;
  let u = aesKeys.value.
          filter((x) => x.address === accountAddress.value)
          [0].aesKey;

  let PBK_RSA_verifier = rsaKeys.value.
                         filter((x) => x.address === verifierAddress)
                         [0].rsaPBK;

  const v = d.v;

  let vA = utilFns.strToBig(v.substring(0,16));
  let vB = utilFns.strToBig(v.substring(16));

  const h_txA = d.h_tx_0;
  const h_txB = d.h_tx_1;

  let oA = utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(0,32));
  let oB = utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(32));

  let aA, aB, aC, aD, h_daA, h_daB;

  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 0).call().then((result)=>{aA=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 1).call().then((result)=>{aB=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 2).call().then((result)=>{aC=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 3).call().then((result)=>{aD=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 4).call().then((result)=>{h_daA=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 5).call().then((result)=>{h_daB=result});      

  const dA = await performAES(u, BigInt(aA).toString(16), 'decrypt').replace(/\s+/g, "");
  const dB = await performAES(u, BigInt(aB).toString(16), 'decrypt').replace(/\s+/g, "");
  const dC = await performAES(u, BigInt(aC).toString(16), 'decrypt').replace(/\s+/g, "");
  const dD = await performAES(u, BigInt(aD).toString(16), 'decrypt').replace(/\s+/g, "");

  const k = utilFns.oneTimeKey(16);
  ephemereForOwnership.value = k;

  const e_rsA = await performAES(k, dA, 'encrypt').replace(/\s+/g, "");
  const e_rsB = await performAES(k, dB, 'encrypt').replace(/\s+/g, "");
  const e_rsC = await performAES(k, dC, 'encrypt').replace(/\s+/g, "");
  const e_rsD = await performAES(k, dD, 'encrypt').replace(/\s+/g, "");
  
  const kPrime = await performRSA(PBK_RSA_verifier, k, 'encrypt');

  userProofCards.value.data[1].kPrime = kPrime;
  userProofCards.value.data[1].e_rs = e_rsA + e_rsB + e_rsC + e_rsD;

  let h_key = utilFns.hashStr(u);
  let h_keyA = utilFns.hexToBig(h_key.substring(0,32));
  let h_keyB = utilFns.hexToBig(h_key.substring(32));

  let nonce = d.nonce;
  let n = d.n;
  let h_dn = utilFns.hashStr(dA+dB+dC+dD+v+n);
  let h_dnA = utilFns.hexToBig(h_dn.substring(0,32));
  let h_dnB = utilFns.hexToBig(h_dn.substring(32));

  await axios.get(`${url}/zokratesOwnershipHashes`, 
  { params: {
      u: utilFns.strToBig(u),
      dA: utilFns.strToBig(dA),
      dB: utilFns.strToBig(dB),
      dC: utilFns.strToBig(dC),
      dD: utilFns.strToBig(dD),
      vA: vA,
      vB: vB,
      aA: aA,
      aB: aB,
      aC: aC,
      aD: aD,
      oA: oA,
      oB: oB,
      n: n,
      h_keyA: h_keyA,
      h_keyB: h_keyB,
      h_txA: h_txA,
      h_txB: h_txB,
      h_daA: h_daA,
      h_daB: h_daB,
      h_dnA: h_dnA,
      h_dnB: h_dnB
    }},
    {
      transformResponse: [data => data]
    }).then((res) => {
      let j = res.data
      zkSNARKsOwnershipHashes.value.push([j.proof.a, j.proof.b, j.proof.c]);
      zkSNARKsOwnershipHashes.value.push(j.inputs);
    });
  return zkSNARKsOwnershipHashes.value;
}

async function generateOwnershipProofIPFS(){
  const d = userProofCards.value[1].data;
  const userAddress = accountAddress.value;
  
  let u = aesKeys.value.
          filter((x) => x.address === accountAddress.value)
          [0].aesKey;

  let aA, aB, aC, aD;

  const v = d.v;
  let oA = utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(0,32));
  let oB = utilFns.hexToBig(utilFns.hashStr(d.v + u).substring(32));

  const k = ephemereForOwnership.value;

  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 0).call().then((result)=>{aA=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 1).call().then((result)=>{aB=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 2).call().then((result)=>{aC=result});
  await zaestContract.methods.userDataSmartContract(userAddress, oA, oB, 3).call().then((result)=>{aD=result});

  const dA = await performAES(u, BigInt(aA).toString(16), 'decrypt').replace(/\s+/g, "");
  const dB = await performAES(u, BigInt(aB).toString(16), 'decrypt').replace(/\s+/g, "");
  const dC = await performAES(u, BigInt(aC).toString(16), 'decrypt').replace(/\s+/g, "");
  const dD = await performAES(u, BigInt(aD).toString(16), 'decrypt').replace(/\s+/g, "");

  const e_rsA = await performAES(k, dA, 'encrypt').replace(/\s+/g, "");
  const e_rsB = await performAES(k, dB, 'encrypt').replace(/\s+/g, "");
  const e_rsC = await performAES(k, dC, 'encrypt').replace(/\s+/g, "");
  const e_rsD = await performAES(k, dD, 'encrypt').replace(/\s+/g, "");

  let cA =  d.c.substring(0,16);
  let cB =  d.c.substring(16,32);
  let cC =  d.c.substring(32,48);
  let cD =  d.c.substring(48) + "_".repeat(64-d.c.length);
  
  let h_ipfs_p = utilFns.hashHex(utilFns.strToHex(e_rsA+e_rsB+e_rsC+e_rsD+cA+cB+cC+cD));
  let h_ipfs_p0 = utilFns.hexToBig(h_ipfs_p.substring(0,32));
  let h_ipfs_p1 = utilFns.hexToBig(h_ipfs_p.substring(32));

  if(placeToIPFS.value[0]==="true" && placeToIPFS.value[1]===1){ 
      let d = "value of e_rs: " + e_rsA + " " + e_rsB + " " + e_rsC + " " + e_rsD;
      const f = new File([d], 'zaest_onboarding_proof.txt');
      const cid = await storageClient.put([f]);
      userProofCards.value[1].data.c = cid;
      userProofCards.value[1].texts["IPFS CID (optional)"] = cid;
      placeToIPFS.value[0]="false";
  }    

  await axios.get(`${url}/zokratesOwnershipIPFS`, 
    { params: {
        e_rsA: utilFns.hexToBig(e_rsA),
        e_rsB: utilFns.hexToBig(e_rsB),
        e_rsC: utilFns.hexToBig(e_rsC),
        e_rsD: utilFns.hexToBig(e_rsD),
        cA: utilFns.strToBig(cA),
        cB: utilFns.strToBig(cB),
        cC: utilFns.strToBig(cC),
        cD: utilFns.strToBig(cD),  
      }
    },
    {
      transformResponse: [data => data]
    }).then((res) => {
      let j = res.data
      zkSNARKsOwnershipIPFS.value.push([j.proof.a, j.proof.b, j.proof.c]);
      zkSNARKsOwnershipIPFS.value.push(j.inputs);
    });
  return zkSNARKsOwnershipIPFS.value;
}

async function performAES(aesKeyParam, aesDataParam, aesFunctionParam) {
  let result = '';
  await axios.get(`${url}/aes`, { params: {
    aesKeyParam: aesKeyParam,
    aesDataParam: aesDataParam,
    aesFunctionParam: aesFunctionParam,
  }}).then((response) => {
    result = aesFunctionParam === "encrypt" ?
    response['data'][1].substring(14) : response['data'][0].substring(9);
  });
  return result;
}

async function performRSA(rsaKeyParam, rsaDataParam, rsaFunctionParam) {
  let result = '';
  await axios.get(`${url}/rsa`, { params: {
    rsaKeyParam: rsaKeyParam,
    rsaDataParam: rsaDataParam,
    rsaFunctionParam: rsaFunctionParam,
  }}).then((response) => {
    result = response['data'][1].substring(4);
  })
  return result;
}

const storeAESkey = () => {
  aesKeys.value.push({
    "address": accountAddress.value,
    "aesKey": secondaryKeysCards.value[0].inputs["AES key"] ? 
              secondaryKeysCards.value[0].inputs["AES key"] :
              secondaryKeysCards.value[0].texts["generated AES key"], 
  })
}

const storeRSAkeys = () => {
  rsaKeys.value.push({
    "address": accountAddress.value,
    "rsaPBK": secondaryKeysCards.value[1].inputs["RSA public key (PBK)"] ? 
              secondaryKeysCards.value[1].inputs["RSA public key (PBK)"] :
              secondaryKeysCards.value[1].texts["generated RSA public key"], 
    "rsaPVK": secondaryKeysCards.value[1].inputs["RSA private key (PVK)"] ? 
              secondaryKeysCards.value[1].inputs["RSA private key (PVK)"] :
              secondaryKeysCards.value[1].texts["generated RSA private key"], 
  })
}

const notification = (title, message) => {
  ElNotification({
    title: title,
    message: h('i', { style: 'color: black' }, message),
  })
}

notification("Welcome", "Please connect your wallet and onboard your secondary keys (in dApp) to begin");

</script>

<script>
export default {
  name: "App",
};
</script>