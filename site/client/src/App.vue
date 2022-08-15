<template>
  <title></title>
  <button @click="fetchData">Fetch Data</button>
  <p>Data retrieved: {{ message }}</p>

  <SimpleCard :cardTitle="cardTitle"></SimpleCard>
  <InputsCard :inputsTitle="inputsTitle"></InputsCard>  
</template>

<script setup>
import { ref } from "vue";
import SimpleCard from "./components/SimpleCard.vue";
import InputsCard from "./components/InputsCard.vue";


const axios = require("axios");

const message = ref("");

const cardTitle = ref("test");
const inputsTitle = ref("test2");

function fetchData() {
  axios.get("/start_python").then(function (response) {
    console.log(response);
    message.value = response;
  });
}
</script>

<script>
export default {
  name: "App",
};
</script>
