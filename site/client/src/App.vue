<template>
  <title>Backend Experiments</title>
  <button @click="fetchAESData">Fetch AES Data</button>
  <p>Data retrieved: {{ AESresponse }}</p>
  <p>AES data: {{ aesData }}</p>
  <p>AES function: {{ aesFunction }}</p>
  <button @click="fetchRSAKeys">Fetch RSA Keys</button>
  <p>Data retrieved: {{ RSAkeysResponse }}</p>
  <p>PVK: {{ rsaPrivateKey }}</p>
  <p>PBK: {{ rsaPublicKey }}</p>
  <button @click="fetchRSAData">Fetch RSA Data</button>
  <p>Data retrieved: {{ RSAresponse }}</p> 
  <p>RSA data: {{ rsaData }}</p>
  <p>RSA function: {{ rsaFunction }}</p>
  <button @click="killPython">Kill Python</button>
  <p>Data received: {{ killPythonResponse }}</p> 
  <p></p>
  <SimpleCard :cardTitle="cardTitle"></SimpleCard>
  <InputsCard :inputsTitle="inputsTitle"></InputsCard>  
</template>

<script setup>
import { ref } from "vue";
import SimpleCard from "./components/SimpleCard.vue";
import InputsCard from "./components/InputsCard.vue";

const axios = require("axios");

const AESresponse = ref("");
const RSAkeysResponse = ref("");
const RSAresponse = ref("");

const cardTitle = ref("test");
const inputsTitle = ref("test2");

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

/*
//data update request parameters
const dPrime = ref("");
const updateOp = ref("");
const args = ref("");
const variableRequested = ref("");
const tLimit = ref("");
const RSA_PBK_Verifier = ref("");
const RSA_PVK_Verifier = ref("");
const RSA_PBK_User = ref("");
const RSA_PVK_User = ref("");
*/

function performAES(aesKeyParam, aesDataParam, aesFunctionParam) {
  axios.get("/aes", { params: { 
    aesKeyParam: aesKeyParam,
    aesDataParam: aesDataParam,
    aesFunctionParam: aesFunctionParam,
  }}).then((response) => {
    AESresponse.value = response;
    aesData.value = aesFunction.value === "encrypt" ? 
    response['data'][1].substring(14) : response['data'][0].substring(9); 
    aesFunction.value = aesFunction.value === "encrypt" ? "decrypt" : "encrypt";
  });
}

function fetchAESData() {
  performAES(aesKey.value, aesData.value, aesFunction.value);
}

function getRSAKeys() {
  axios.get("/rsaKeys").then((response) =>{
    RSAkeysResponse.value = response;
    rsaPrivateKey.value = response['data'][0].substring(5);
    rsaPublicKey.value = response['data'][1].substring(5);
  })
}

function fetchRSAKeys() {
  getRSAKeys();
}

function performRSA(rsaKeyParam, rsaDataParam, rsaFunctionParam) {
  axios.get("/rsa", { params: {
    rsaKeyParam: rsaKeyParam,
    rsaDataParam: rsaDataParam,
    rsaFunctionParam: rsaFunctionParam,    
  }}).then((response) => {
    RSAresponse.value = response;   
    rsaData.value = response['data'][1].substring(4);
    rsaFunction.value = rsaFunction.value === "encrypt" ? "decrypt" : "encrypt";
  })
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
  axios.get("/stopPython").then((response) => {
    killPythonResponse.value = response;
  })
}

/*
function encryptRSA(PBK){
  axios.get("/rsa", { params: {
    publicKey: PBK,
  }}).then((response) => {
    return response;
  })
}



function dataUpdateRequestParams(){
  const paddedDPrime = dPrime.value + "_".repeat(64-dPrime.value.length);
  const paddedUpdate = updateOp.value + "_".repeat(16-updateOp.value.length);
  const paddedArgs   = args.value + "_".repeat(16-args.value.length);
  const paddedVar    = variableRequested.value + "_".repeat(16-variableRequested.length);
  const ru = paddedDPrime + paddedUpdate + paddedArgs + paddedVar;
  const k  = oneTimeKey(16);
  const kPrime = encryptRSA(RSA_PBK_Verifier);

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
*/

</script>

<script>
export default {
  name: "App",
};
</script>
