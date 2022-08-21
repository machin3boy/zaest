<template>
  <div class="flex flex-col bg-stone-900 text-white min-h-screen" > 
    <ParticlesBackground v-if="currentPath==='#/'||currentPath==='#/about'"/>
    <Menu :connectionStatus="connectionStatus" @connect="connectMetamask"/>
    <component :is="currentView" :props="propsToPass()" class="flex grow"/>
    <el-backtop :right="30" :bottom="30" />
    <Footer />
  </div>
</template>

<script setup>
import { ref, computed } from "vue";

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

import Web3 from 'web3';
import axios from 'axios';

import "./util.js";

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

async function connectMetamask(){
  connectionStatus.value = 'processing';
  if (window.ethereum) {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
    const account = accounts[0];
    connectionStatus.value = 'wallet connected';
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

</script>

<script>
export default {
  name: "App",
};
</script>
