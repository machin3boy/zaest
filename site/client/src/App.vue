<template>
  <img alt="Vue logo" src="./assets/logo.png">
  <HelloWorld msg="Welcome to Your Vue.js App"/>
  <button @click="fetchData">Fetch Data</button>
  <p>Data retrieved: {{ message }}</p>
</template>

<script setup>
import { ref } from 'vue';
import HelloWorld from './components/HelloWorld.vue'
const axios = require('axios');

const message = ref("");

function fetchData(){
  axios.get("/start_python").then(function (response){
    console.log(response);
    message.value = response;
  });
}
</script>

<script>
export default {
  name: 'App',
  components: {
    HelloWorld
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
