<template>
  <div class="flex flex-col bg-stone-900 text-white min-h-screen" > 
    <ParticlesBackground v-if="currentPath!=='#/userpage' &&
                               currentPath!=='#/verifierpage' &&
                               currentPath!=='#/secondarykeys'" />
    <Menu :connectionStatus="connectionStatus" @connect="connectMetamask"/>
   
    <About v-if="currentPath==='#/about'" class="flex grow" />
    <SecondaryKeys v-else-if="currentPath==='#/secondarykeys'" class="flex grow"
      @updateSecondaryKeysAES="updateKeysAES" @buttonSecondaryKeysAES="handleActionAES"
      @updateSecondaryKeysRSA="updateKeysRSA" @buttonSecondaryKeysRSA="handleActionRSA"
      :props="secondaryKeysCards"
    />
    <UserPage v-else-if="currentPath==='#/userpage'" class="flex grow" />
    <VerifierPage v-else-if="currentPath==='#/verifierpage'" class="flex grow"
      :request="verifierRequestCards" :submitted="verifiersSubmittedRequests" :received="verifiersReceivedProofs"
      :account="accountAddress"
      @updateOnboardingReq="updateOnboardingReq" @buttonOnboardingReq="handleActionOnboardingReq"
      @updateOwnershipReq="updateOwnershipReq" @buttonOwnershipReq="handleActionOwnershipReq"
    />
    <Home v-else />
   
    <p class="text-2xl">
        {{verifiersSubmittedRequests}}
    </p>

    <p class="text-2xl">
      {{verifierRequestCards}}
    </p>
    <p class="text-2xl">
      {{fieldTest}}
    </p>
    <p class="text-2xl">
        {{secondaryKeysCards}}
    </p>
    <p class="text-2xl">
        {{aesKeys}}
    </p>
    <p class="text-2xl">
        {{rsaKeys}}
    </p>
    <el-backtop :right="30" :bottom="30" class="bg-black" />
    <Footer />
  </div>
</template>

<script setup>
import { ref, computed, h } from "vue";
import { ElNotification } from 'element-plus'

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
const contractAddress = "0x31c07a2375d68195FE3F69A3F506f27e97F3F02E";
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

const userDataCards = ref([]);

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
    "generated ephemeral key": "",
  },
  "buttons": [
    "generate ephemeral key",
    "send request to smart contract",
  ]
}]);

const usersActiveRequestCards = ref([]);
const verifiersSubmittedRequests = ref([]);
const verifiersReceivedProofs = ref([]);

const aesKeys = ref([]);
const rsaKeys = ref([]);

const fieldTest = ref('');

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

const handleActionAES = (...args) => {
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

const handleActionRSA = async (...args) => {
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
              filter((x) => x.address === accountAddress.value)
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

const handleActionOnboardingReq = async (...args) => {
  if(args[0]==='generate ephemeral key'){
    verifierRequestCards.value[0].texts["generated ephemeral key"] = utilFns.oneTimeKey(16); 
  }
  if(args[0]==='send request to smart contract'){


    let i = verifierRequestCards.value[0].inputs;
    const userAddress = i["user address"];

    let t = verifierRequestCards.value[0].texts;
    let p = rsaKeys.value.
            filter((x) => x.address === userAddress)
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
    const k  = t["generated ephemeral key"];
    const e_ru = await performAES(k, ru, 'encrypt');
    const kPrime = await performRSA(p, k, 'encrypt');
    const nonce = utilFns.strToBig(utilFns.oneTimeKey(16)).toString();
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
        d.setSeconds(d.getSeconds() + parseInt(tLimit));

        let dateString = ("0" + d.getDate()).slice(-2) + "-" + ("0"+(d.getMonth()+1)).slice(-2) + "-" +
        d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);

        usersActiveRequestCards.value.push({
          "texts": {
            "request type": "onboard new data",
            "requesting verifier": accountAddress.value,
            "requesting nonce": nonce,
            "request expiry time": dateString,
          },
          "buttons": [
            "select request",
            "ignore request"
          ]
        })

        verifiersSubmittedRequests.value.push({
          "verifier": accountAddress.value,
          "texts": {
            "request type": "onboard new data",
            "requested account": userAddress,
            "requesting nonce": nonce,
            "request expiry time": dateString,
          },
        })

        notification("Smart Contract", "Data onboarding request submitted to smart contract")
      })
  }
}

const handleActionOwnershipReq = async (...args) => {
  if(args[0]==='generate ephemeral key'){
    verifierRequestCards.value[1].texts["generated ephemeral key"] = utilFns.oneTimeKey(16); 
  }
  if(args[0]==='send request to smart contract'){

    let v = verifierRequestCards.value[1].inputs["field requested"];
    let userAddress = verifierRequestCards.value[1].inputs["user address"];
    let n = verifierRequestCards.value[1].texts["generated ephemeral key"];
            
    let p = rsaKeys.value.
            filter((x) => x.address === accountAddress.value)
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

        let dateString = ("0" + d.getDate()).slice(-2) + "-" + ("0"+(d.getMonth()+1)).slice(-2) + "-" +
        d.getFullYear() + " " + ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);

        verifiersSubmittedRequests.value.push({
          "verifier": accountAddress.value,
          "title": "request " + n,
          "texts": {
            "request type": "proof of ownership",
            "requested account": userAddress,
            "request time": dateString,
          },
        })


        notification("Smart Contract", "Proof of data ownership request submitted to smart contract");
        console.log("Hash of the transaction: " + res);
      })
  }
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
  return result.replace(/\s/g, '');
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

</script>

<script>
export default {
  name: "App",
};
</script>
