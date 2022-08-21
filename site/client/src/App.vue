<template>
  <div class="flex flex-col bg-stone-900 text-white min-h-screen" > 
    <ParticlesBackground v-if="currentPath!=='#/userdata' &&
                               currentPath!=='#/userpage' &&
                               currentPath!=='#/verifierpage' &&
                               currentPath!=='#/secondarykeys'" />
    <Menu :connectionStatus="connectionStatus" @connect="connectMetamask"/>
    <component :is="currentView" :props="propsToPass()" class="flex grow"
      @updateSecondaryKeysAES="updateKeysAES" @buttonSecondaryKeysAES="handleActionAES"
      @updateSecondaryKeysRSA="updateKeysRSA" @buttonSecondaryKeysRSA="handleActionRSA"
    />
    <p class="text-2xl">
      {{fieldTest}}
    </p>
    <p class="text-2xl">
        {{secondaryKeysCards}}
    </p>
    <p class="text-2xl">
        {{aesKeys}}
    </p>
    <el-backtop :right="30" :bottom="30" />
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
import UserData from "./components/UserData.vue";
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
  '/userdata': UserData,
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

const propsToPass = () => {
  if(currentPath.value==='#/secondarykeys')
    return secondaryKeysCards;
  return;
}

const secondaryKeysCards = ref([
{
  "title": "AES keys",
  "inputs": {
    "input AES key": ""
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
    "input RSA public key (PBK)": "",
    "input RSA private key (PVK)": "",
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

const aesKeys = ref([]);
const rsaKeys = ref([]);

const fieldTest = ref('');

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
    notification("Secondary Keys", "Your key was successfully onboarded");
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
        console.log("Hash of the transaction: " + res)
      })
  }
}

const storeAESkey = () => {
  aesKeys.value.push({
    "address": accountAddress.value,
    "aesKey": secondaryKeysCards.value[0].inputs["input AES key"] ? 
              secondaryKeysCards.value[0].inputs["input AES key"] :
              secondaryKeysCards.value[0].texts["generated AES key"], 
  })
}

const storeRSAkeys = () => {
  rsaKeys.value.push({
    "address": accountAddress.value,
    "rsaPBK": secondaryKeysCards.value[1].inputs["input RSA public key (PBK)"] ? 
              secondaryKeysCards.value[1].inputs["input RSA public key (PBK)"] :
              secondaryKeysCards.value[1].texts["generated RSA public key"], 
    "rsaPVK": secondaryKeysCards.value[1].inputs["input RSA private key (PVK)"] ? 
              secondaryKeysCards.value[1].inputs["input RSA private key (PVK)"] :
              secondaryKeysCards.value[1].texts["generated RSA private key"], 
  })
}

const notification = (title, message) => {
  ElNotification({
    title: title,
    message: h('i', { style: 'color: teal' }, message),
  })
}

</script>

<script>
export default {
  name: "App",
};
</script>
