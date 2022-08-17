<template>
  <title>Backend Experiments</title>
  <InputsCard :fields="dataUpdateFields"
              @updateCard="dataUpdateChildInput"
              @generateResults="dataUpdateGenerateResults" class="mt-5 mb-3 mx-3"/>
  <SimpleCard :fields="dataUpdateFields" class="m-3"/>
  <el-button @click="fetchAESData" class="m-3">Fetch AES Data</el-button>
  <p class="mx-6"> Data retrieved: {{ AESresponse }}</p>
  <p class="mx-6"> AES data: {{ aesData }}</p>
  <p class="mx-6"> AES function: {{ aesFunction }}</p>
  <el-button @click="fetchRSAKeys" class="m-3">Fetch RSA Keys</el-button>
  <p class="mx-6"> Data retrieved: {{ RSAkeysResponse }}</p>
  <p class="mx-6"> PVK: {{ rsaPrivateKey }}</p>
  <p class="mx-6"> PBK: {{ rsaPublicKey }}</p>
  <el-button @click="fetchRSAData" class="m-3">Fetch RSA Data</el-button>
  <p class="mx-6"> Data retrieved: {{ RSAresponse }}</p> 
  <p class="mx-6"> RSA data: {{ rsaData }}</p>
  <p class="mx-6"> RSA function: {{ rsaFunction }}</p>
  <el-button @click="killPython" class="m-3">Kill Python</el-button>
  <p class="mx-6"> Data received: {{ killPythonResponse }}</p> 
  <p class="mx-6 my-5"> </p>

</template>

<script setup>
import { ref } from "vue";
import SimpleCard from "./components/SimpleCard.vue";
import InputsCard from "./components/InputsCard.vue";
const CryptoJS = require('crypto-js');

const axios = require("axios");
const url = "http://localhost:3001";

const AESresponse = ref("");
const RSAkeysResponse = ref("");
const RSAresponse = ref("");

//data update request card
const dataUpdateFields = ref({
  "title update": "input data update params",
  "title results": "data update tx details",
  "params": {
    "dPrime": "",
    "updateOp": "",
    "args": "",
    "variableRequested": "",
    "tLimit": 300,
  },
  "results": {
    "e_ru": "",
    "kPrime": "",
    "h_dp": "",
    "h_ru": "",
    "nonce": "",
    "tLimit": 0, 
  }
})

function dataUpdateChildInput(field, input) {
  dataUpdateFields.value[field] = input;
}

function dataUpdateGenerateResults(){
  const paddedDPrime = dPrime.value + "_".repeat(64-dPrime.length);
  const paddedUpdate = update.value + "_".repeat(16-update.length);
  const paddedArgs   = args.value + "_".repeat(16-args.length);
  const paddedVar    = variable.value + "_".repeat(16-variable.length);
  const ru = paddedDPrime + paddedUpdate + paddedArgs + paddedVar;
  const h_dp = hashStr(paddedDPrime);
  const h_ru = hashStr(ru);
  const e_ru = encryptAES(ru);
  const k  = oneTimeKey(16);
  const kPrime = encryptRSA(rsaPublicKey.value);
  const nonce = oneTimeKey(16);
  dataUpdateFields.value.results['e_ru'] = e_ru;
  dataUpdateFields.value.results['kPrime'] = kPrime;
  dataUpdateFields.value.results['h_dp'] = strToBig(h_dp);
  dataUpdateFields.value.results['h_ru'] = strToBig(h_ru);
  dataUpdateFields.value.results['nonce'] = nonce;
  dataUpdateFields.value.results['tLimit'] = dataUpdateFields.value.params['tLimit'];
}

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

function performAES(aesKeyParam, aesDataParam, aesFunctionParam) {
  axios.get(`${url}/aes`, { params: { 
    aesKeyParam: aesKeyParam,
    aesDataParam: aesDataParam,
    aesFunctionParam: aesFunctionParam,
  }}).then((response) => {
    AESresponse.value = response;
    aesData.value = aesFunction.value === "encrypt" ? 
    response['data'][1].substring(14) : response['data'][0].substring(9); 
    aesFunction.value = aesFunction.value === "encrypt" ? "decrypt" : "encrypt";
  });
  return aesData.value;
}

function fetchAESData() {
  performAES(aesKey.value, aesData.value, aesFunction.value);
}

function getRSAKeys() {
  axios.get(`${url}/rsaKeys`).then((response) =>{
    RSAkeysResponse.value = response;
    rsaPrivateKey.value = response['data'][0].substring(5);
    rsaPublicKey.value = response['data'][1].substring(5);
  })
  return [rsaPrivateKey.value, rsaPublicKey.value];
}

function fetchRSAKeys() {
  getRSAKeys();
}

function performRSA(rsaKeyParam, rsaDataParam, rsaFunctionParam) {
  axios.get(`${url}/rsa`, { params: {
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
    return CryptoJS.SHA256(string);
}

function hexToBig(num) {
    return BigInt(num)
}

function bigToHex(num) {    
    return '0x' + BigInt(num).toString(16)
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
    u8 = Uint8Array.from(buf);
    u8.forEach(function (i) {
        let h = i.toString(16);
        if (h.length % 2) { h = '0' + h; }
            hex.push(h);
    });
    return BigInt('0x' + hex.join(''));
}

function u32arrToHex(u32Arr) {
    let hex = [];
    u32 = Uint32Array.from(u32Arr)
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
