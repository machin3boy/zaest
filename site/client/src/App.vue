<template>
  <div class="flex grow flex-col bg-stone-900 text-white" > 
    <div id="app">
      <Particles
          id="tsparticles"
          :particlesInit="particlesInit"
          :particlesLoaded="particlesLoaded"
          :options="
          { 
              particles: {
                number: {
                  value: 50,
                  density: {
                    enable: true,
                    value_area: 800
                  }
                },
                backgroundMode: {
                      enable: true,
                      zIndex: -1
                },
                color: {
                  value: '#fef08a'
                },
                shape: {
                  type: 'circle',
                  stroke: {
                    width: 0,
                    color: '#000000'
                  },
                  polygon: {
                    nb_sides: 5
                  },
                  image: {
                    src: 'img/github.svg',
                    width: 100,
                    height: 100
                  }
                },
                opacity: {
                  value: 0.2,
                  random: false,
                  anim: {
                    enable: false,
                    speed: 1,
                    opacity_min: 0.1,
                    sync: false
                  }
                },
                size: {
                  value: 3,
                  random: true,
                  anim: {
                    enable: false,
                    speed: 40,
                    size_min: 0.1,
                    sync: false
                  }
                },
                line_linked: {
                  enable: true,
                  distance: 150,
                  color: 'fef08a',
                  opacity: 0.3,
                  width: 1
                },
                move: {
                  enable: true,
                  speed: 0.3,
                  direction: 'none',
                  random: false,
                  straight: false,
                  out_mode: 'out',
                  bounce: false,
                  attract: {
                    enable: false,
                    rotateX: 600,
                    rotateY: 1200
                  }
                }
              },
              interactivity: {
                detect_on: 'canvas',
                events: {
                  onhover: {
                    enable: false,
                    mode: 'repulse'
                  },
                  onclick: {
                    enable: false,
                    mode: 'push'
                  },
                  resize: true
                },
                modes: {
                  grab: {
                    distance: 400,
                    line_linked: {
                      opacity: 1
                    }
                  },
                  bubble: {
                    distance: 400,
                    size: 40,
                    duration: 2,
                    opacity: 8,
                    speed: 3
                  },
                  repulse: {
                    distance: 200,
                    duration: 0.4
                  },
                  push: {
                    particles_nb: 4
                  },
                  remove: {
                    particles_nb: 2
                  }
                }
              },
              retina_detect: true
            }"
        />
    </div>
    <Menu :connectionStatus="connectionStatus" @connect="connectMetamask" />
      <div class="flex mt-10 p-10 flex-wrap">
        <div class="flex flex-col basis-2/3 grow justify-center px-10 mb-10">
          <h1 class="font-bold text-5xl">Welcome to Zaest</h1>
          <p class="mt-5 text-xl">Lorem ipsum dolor sit amet, consectetur adipisci 
            elit, sed eiusmod tempor incidunt ut labore et dolore 
            magna aliqua. Ut enim ad minim veniam, quis nostrum
            exercitationem ullam corporis suscipit laboriosam, 
            nisi ut aliquid ex ea commodi consequatur. Quis 
            aute iure reprehenderit in voluptate velit esse. 
          </p>
        </div>
        <div class="flex basis-1/3 grow justify-center px-10 min-w-fit mb-10">
          <img src="../src/assets/lemon.png"/>
        </div>
      </div>

      <div class="flex px-10 flex-wrap-reverse">
        <div class="flex basis-1/3 grow justify-center px-10 min-w-fit">
          <img src="../src/assets/lemon.png"/>
        </div>
        <div class="flex flex-col basis-2/3 grow justify-center px-10 mb-10">
          <h1 class="font-bold text-5xl">Welcome to Zaest</h1>
          <p class="mt-5 text-xl">Lorem ipsum dolor sit amet, consectetur adipisci 
            elit, sed eiusmod tempor incidunt ut labore et dolore 
            magna aliqua. Ut enim ad minim veniam, quis nostrum
            exercitationem ullam corporis suscipit laboriosam, 
            nisi ut aliquid ex ea commodi consequatur. Quis 
            aute iure reprehenderit in voluptate velit esse. 
          </p>
        </div>
      </div>    

    <el-backtop :right="30" :bottom="30" />
  </div>
</template>

<script setup>

import { ref } from "vue";
import SimpleCard from "./components/SimpleCard.vue";
import InputsCard from "./components/InputsCard.vue";
import Menu from "./components/Menu.vue";
import axios from 'axios';
import { loadFull } from "tsparticles";
import InputField from "./components/InputField.vue";

import Web3 from 'web3';
const connectionStatus = ref('Connect Wallet');

const particlesInit = async (engine) => {
    await loadFull(engine);
}

const particlesLoaded = async (container) => {
    console.log("Particles container loaded", container);
}

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


const CryptoJS = require('crypto-js');

const url = "http://localhost:3001";

const AESresponse = ref("");
const RSAkeysResponse = ref("");
const RSAresponse = ref("");
const zOnboardingHashesResponse = ref('');
const zOnboardingAESResponse = ref('');
const zOnboardingIPFSResponse = ref('');

//AES parameters
const aesKey = ref("zaesttestkey1234");
const aesData = ref("abcdefgh12345678abcdefgh12345678");
const aesFunction = ref("encrypt");

//RSA parameters
const rsaPublicKey  = ref("");
const rsaPrivateKey = ref("");
const rsaData = ref("abcdefgh12345678");
const rsaFunction = ref("encrypt");

//Log what /stopPython returns on GET
const killPythonResponse = ref("");

//data update request card
const dataUpdateFields = ref({
  "title update": "input data update params",
  "title results": "data update tx details",
  "button text": "call smart contract",
  "params": {
    "dPrime": "",
    "updateOp": "",
    "args": "",
    "variableRequested": "",
    "tLimit": "300",
  },
  "results": {
    "e_ru": "",
    "k": "",
    "kPrime": "",
    "h_dp_0": "",
    "h_dp_1": "",
    "h_ru_0": "",
    "h_ru_1": "",
    "nonce": "",
    "tLimit": "", 
  }
})

const updateRequestDecrypted = ref({
  "title results": "data update tx decrypted",
  "button text": "decrypt request",
  "results": {
    "k": "",
    "ru": "",
    "h_ru_0": "",
    "h_ru_1": "",
    "dPrime": "",
    "h_dp_0": "",
    "h_dp_1": "",
    "updateOp": "",
    "args": "",
    "variableRequested": "",
    "c": "lasdfjpoasidjfsapodfijasdoifjaspdofijadsjasdpofijasdojfasdj",
    "tLimit": "",
  }
})

const zkSNARKsOnboarding = ref({
  "title results": "zk-SNARKs proof",
  "button text": "generate zk-SNARKs proof",
  "results": {
    "proof hashes": "",
    "proof AES": "",
    "proof IPFS": "",
  }
})

function dataUpdateChildInput(field, input) {
  dataUpdateFields.value.params[field] = input;
}

async function decryptUpdateRequest(){
  const d = dataUpdateFields.value.results;
  updateRequestDecrypted.value.results["k"] = await performRSA(rsaPrivateKey.value, d.kPrime, 'decrypt');
  const ru = await performAES(aesKey.value, d.e_ru, 'decrypt');
  updateRequestDecrypted.value.results["ru"] = ru
  updateRequestDecrypted.value.results['h_ru_0'] = d.h_ru_0;
  updateRequestDecrypted.value.results['h_ru_1'] = d.h_ru_1;
  updateRequestDecrypted.value.results["dPrime"] = ru.substring(0, 64);
  updateRequestDecrypted.value.results['h_dp_0'] = d.h_dp_0;
  updateRequestDecrypted.value.results['h_dp_1'] = d.h_dp_1;
  updateRequestDecrypted.value.results["updateOp"] = ru.substring(64, 80);
  updateRequestDecrypted.value.results["args"] = ru.substring(80, 96);
  updateRequestDecrypted.value.results["variableRequested"] = ru.substring(96);
  updateRequestDecrypted.value.results["tLimit"] = d.tLimit; 
} 

async function dataUpdateGenerateResults(){
  const p = dataUpdateFields.value.params;
  const paddedDPrime = p.dPrime + "_".repeat(64-p.dPrime.length);
  const paddedUpdate = p.updateOp + "_".repeat(16-p.updateOp.length);
  const paddedArgs   = p.args + "_".repeat(16-p.args.length);
  const paddedVar    = p.variableRequested + "_".repeat(32-p.variableRequested.length);
  const ru = paddedDPrime + paddedUpdate + paddedArgs + paddedVar;
  const h_dp = hashStr(paddedDPrime);
  const h_dp_0 = h_dp.substring(0, h_dp.length/2);
  const h_dp_1 = h_dp.substring(h_dp.length/2); 
  const h_ru = hashStr(ru);
  const h_ru_0 = h_ru.substring(0, h_ru.length/2);
  const h_ru_1 = h_ru.substring(h_ru.length/2);
  const e_ru = await performAES(aesKey.value, ru, 'encrypt');
  const k  = oneTimeKey(16);
  const kPrime = await performRSA(rsaPublicKey.value, k, 'encrypt');
  const nonce = oneTimeKey(16);
  dataUpdateFields.value.results['k'] = k;
  dataUpdateFields.value.results['e_ru'] = e_ru;
  dataUpdateFields.value.results['kPrime'] = kPrime;
  dataUpdateFields.value.results['h_dp_0'] = strToBig(h_dp_0).toString();
  dataUpdateFields.value.results['h_dp_1'] = strToBig(h_dp_1).toString();
  dataUpdateFields.value.results['h_ru_0'] = strToBig(h_ru_0).toString();
  dataUpdateFields.value.results['h_ru_1'] = strToBig(h_ru_1).toString();
  dataUpdateFields.value.results['nonce'] = nonce;
  dataUpdateFields.value.results['tLimit'] = dataUpdateFields.value.params['tLimit'];
  console.log("data update generate results");
}

async function generateOnboardingProofHashes(){
  const d = updateRequestDecrypted.value.results;
  let a = await performAES(aesKey.value, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA = a.substring(0,32);
  let aB = a.substring(32,64);
  let aC = a.substring(64,96);
  let aD = a.substring(96, 128);
  let h_da = hashHex(strToHex(d.dPrime.substring(0, 16)) + 
                     strToHex(d.dPrime.substring(16, 32)) + 
                     strToHex(d.dPrime.substring(32, 48)) + 
                     strToHex(d.dPrime.substring(48)) + 
                     a + strToHex(aesKey.value));
  await axios.get(`${url}/zokratesOnboardingHashes`, 
    { params: {
      u:  strToBig(aesKey.value),
      dA: strToBig(d.dPrime.substring(0, 16)),
      dB: strToBig(d.dPrime.substring(16, 32)),
      dC: strToBig(d.dPrime.substring(32, 48)),
      dD: strToBig(d.dPrime.substring(48)),
      up: strToBig(d.updateOp),
      ar: strToBig(d.args),
      vA: strToBig(d.variableRequested.substring(0, 16)),
      vB: strToBig(d.variableRequested.substring(16)),
      aA: hexToBig(aA),
      aB: hexToBig(aB),
      aC: hexToBig(aC),
      aD: hexToBig(aD),
      oA: hexToBig(hashStr(d.variableRequested + aesKey.value).substring(0,32)),
      oB: hexToBig(hashStr(d.variableRequested + aesKey.value).substring(32)),
      h_keyA: hexToBig(hashStr(aesKey.value).substring(0, 32)),
      h_keyB: hexToBig(hashStr(aesKey.value).substring(32)),
      h_ruA: hexToBig(hashStr(d.ru).substring(0, 32)),
      h_ruB: hexToBig(hashStr(d.ru).substring(32)),
      h_daA: hexToBig(h_da.substring(0, 32)),
      h_daB: hexToBig(h_da.substring(32)),
      }
    },
    {
      transformResponse: [data => data] 
    }).then((res) => {
      zkSNARKsOnboarding.value.results['proof hahes'] = JSON.stringify(res.data);
      zOnboardingHashesResponse.value = JSON.stringify(res.data);
    });
    return zkSNARKsOnboarding.value.results['proof hashes'];
}

async function generateOnboardingProofAES(){
  const d = updateRequestDecrypted.value.results;
  let a = await performAES(aesKey.value, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA = a.substring(0,32);
  let aB = a.substring(32,64);
  let aC = a.substring(64,96);
  let aD = a.substring(96, 128);
  await axios.get(`${url}/zokratesOnboardingAES`, 
    { params: {
      u:  strToBig(aesKey.value),
      dA: strToBig(d.dPrime.substring(0, 16)),
      dB: strToBig(d.dPrime.substring(16, 32)),
      dC: strToBig(d.dPrime.substring(32, 48)),
      dD: strToBig(d.dPrime.substring(48)),
      aA: hexToBig(aA),
      aB: hexToBig(aB),
      aC: hexToBig(aC),
      aD: hexToBig(aD),
      h_keyA: hexToBig(hashStr(aesKey.value).substring(0, 32)),
      h_keyB: hexToBig(hashStr(aesKey.value).substring(32)),
      h_dpA: hexToBig(hashStr(d.dPrime).substring(0,32)),
      h_dpB: hexToBig(hashStr(d.dPrime).substring(32)),
      }
    },
    {
      transformResponse: [data => data] 
    }).then((res) => {
      zkSNARKsOnboarding.value.results['proof AES'] = JSON.stringify(res.data);
      zOnboardingAESResponse.value = JSON.stringify(res.data);
    });
    return zkSNARKsOnboarding.value.results['proof AES'];
}

async function generateOnboardingProofIPFS(){
  const d = updateRequestDecrypted.value.results;
  let a = await performAES(aesKey.value, d.dPrime, 'encrypt')
  a = a.replace(/\s/g, '');
  let aA =  a.substring(0,32);
  let aB =  a.substring(32,64);
  let aC =  a.substring(64,96);
  let aD =  a.substring(96, 128);
  let oA =  hashStr(d.variableRequested + aesKey.value).substring(0,32);
  let oB =  hashStr(d.variableRequested + aesKey.value).substring(32);
  let cA =  d.c.substring(0,16);
  let cB =  d.c.substring(16,32);
  let cC =  d.c.substring(32,48);
  let cD =  d.c.substring(48) + "_".repeat(64-d.c.length);
  let h_ipfs_d = hashHex(a + oA + oB + strToHex(cA+cB+cC+cD)); 
                         
  await axios.get(`${url}/zokratesOnboardingIPFS`, 
    { params: {
      aA: hexToBig(aA),
      aB: hexToBig(aB),
      aC: hexToBig(aC),
      aD: hexToBig(aD),
      oA: hexToBig(oA),
      oB: hexToBig(oB),
      cA: strToBig(cA),
      cB: strToBig(cB),
      cC: strToBig(cC),
      cD: strToBig(cD),
      h_ipfs_d0: hexToBig(h_ipfs_d.substring(0,32)),
      h_ipfs_d1: hexToBig(h_ipfs_d.substring(32)),
      }
    },
    {
      transformResponse: [data => data] 
    }).then((res) => {
      zkSNARKsOnboarding.value.results['proof IPFS'] = JSON.stringify(res.data);
      zOnboardingIPFSResponse.value = JSON.stringify(res.data);
    });
    return zkSNARKsOnboarding.value.results['proof IPFS'];
}

function generateOnboardingProof(){
  generateOnboardingProofHashes();
  generateOnboardingProofAES();
  generateOnboardingProofIPFS();
}

async function performAES(aesKeyParam, aesDataParam, aesFunctionParam) {
  await axios.get(`${url}/aes`, { params: { 
    aesKeyParam: aesKeyParam,
    aesDataParam: aesDataParam,
    aesFunctionParam: aesFunctionParam,
  }}).then((response) => {
    AESresponse.value = response;
    aesData.value = aesFunctionParam === "encrypt" ? 
    response['data'][1].substring(14) : response['data'][0].substring(9); 
    aesFunction.value = aesFunction.value === "encrypt" ? "decrypt" : "encrypt";
  });
  return aesData.value;    
}

function fetchAESData() {
  performAES(aesKey.value, aesData.value, aesFunction.value);
}

async function getRSAKeys() {
  await axios.get(`${url}/rsaKeys`).then((response) =>{
    RSAkeysResponse.value = response;
    rsaPrivateKey.value = response['data'][0].substring(5);
    rsaPublicKey.value = response['data'][1].substring(5);
  })
  return [rsaPrivateKey.value, rsaPublicKey.value];
}

function fetchRSAKeys() {
  getRSAKeys();
}

async function performRSA(rsaKeyParam, rsaDataParam, rsaFunctionParam) {
  await axios.get(`${url}/rsa`, { params: {
    rsaKeyParam: rsaKeyParam,
    rsaDataParam: rsaDataParam,
    rsaFunctionParam: rsaFunctionParam,    
  }}).then((response) => {
    RSAresponse.value = response;   
    rsaData.value = response['data'][1].substring(4);
    rsaFunction.value = rsaFunction.value === "encrypt" ? "decrypt" : "encrypt";
  })
  return rsaData.value;
}

function fetchRSAData() {
  if(rsaFunction.value === "encrypt"){
    performRSA(rsaPublicKey.value, rsaData.value, rsaFunction.value);
  }
  else{
    performRSA(rsaPrivateKey.value, rsaData.value, rsaFunction.value);
  }
}

function killPython() {
  axios.get(`${url}/stopPython`).then((response) => {
    killPythonResponse.value = response;
  })
}

function oneTimeKey(length) {
    var result           = '';
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
   }
   return result;
}

function hashHex(hexstr) { 
    return CryptoJS.SHA256(CryptoJS.enc.Hex.parse(hexstr)).toString();
}

function hashStr(string){
    return CryptoJS.SHA256(string).toString();
}

function hexToBig(num) {
    return BigInt('0x'+num);
}

function bigToHex(num) {    
    return BigInt(num).toString(16)
}

function strToHex(s){
  return bigToHex(strToBig(s));
}

function strToU8arr(str) {
    return new TextEncoder('utf-8').encode(str)
}

function u8arrToStr(u8arr) {
    return new TextDecoder('utf-7').decode(u8arr)
}

function bigToU8arr(big) {
    const big0 = BigInt(0)
    const big1 = BigInt(1)
    const big8 = BigInt(8)
    if (big < big0) {
        const bits = (BigInt(big.toString(2).length) / big8 + big1) * big8
        const prefix1 = big1 << bits
        big += prefix1
    }
    let hex = big.toString(16)
    if (hex.length % 2) {
        hex = '0' + hex
    }
    const len = hex.length / 2
    const u8 = new Uint8Array(len)
    let i = 0
    let j = 0
    while (i < len) {
        u8[i] = parseInt(hex.slice(j, j + 2), 16)
        i += 1
        j += 2
    }
    return u8
}

function u8arrToBig(buf) {
    let hex = [];
    let u8 = Uint8Array.from(buf);
    u8.forEach(function (i) {
        let h = i.toString(16);
        if (h.length % 2) { h = '0' + h; }
            hex.push(h);
    });
    return BigInt('0x' + hex.join(''));
}

function u32arrToHex(u32Arr) {
    let hex = [];
    let u32 = Uint32Array.from(u32Arr)
    u32.forEach(function (i) {
        let h = i.toString(16);
        hex.push('0'.repeat(8 - h.length) + h)
    })
    return '0x' + hex.join('');
}

function strToBig(str) {
    return u8arrToBig(strToU8arr(str));
}

function bigToStr(big) {
    return u8arrToStr(bigToU8arr(big));
}


</script>

<script>
export default {
  name: "App",
};
</script>
