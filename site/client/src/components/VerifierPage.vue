<template>
   
    <div class="flex flex-col">
        <div >
            <h1 class="text-3xl my-10 ml-10">
            Create New Request: 
            </h1>
            <div class="flex flex-wrap justify-center items-center">
                <div class="flex flex-col basis-1/2 items-center">
                    <Card :fields="request[0]" class="bg-black text-white m-3"
                        @updateCard="(...args)=>$emit('updateOnboardingReq', ...args)"
                        @buttonClick="(...args)=>$emit('buttonOnboardingReq', ...args)"
                    />
                </div>
                <div class="flex flex-col basis-1/2 items-center">
                    <Card :fields="request[1]" class="bg-black text-white m-3"
                        @updateCard="(...args)=>$emit('updateOwnershipReq', ...args)"
                        @buttonClick="(...args)=>$emit('buttonOwnershipReq', ...args)"
                    />
                </div>
            </div>
        </div>

        <div v-if="received.length>0">
            <h1 class="text-3xl my-10 ml-10">
                Received User Proofs:
            </h1>
        </div>

        <div v-if="submitted.length>0" class="mb-10">
            <h1 class="text-3xl my-10 ml-10">
                Previously Submitted Requests:
            </h1>
            <div class="flex flex-wrap justify-center items-center">
                <div v-for="(item, index) in submitted">
                    <Card v-if="item.verifier===account" :fields="item" class="bg-black text-white m-3" />
                </div>
            </div>
        </div>
    </div>
    
</template>

<script setup>
import Card from "./Card";
defineProps(['request', 'received', 'submitted', 'account']);
defineEmits(['updateOnboardingReq', 'buttonOnboardingReq', 'updateOwnershipReq', 'buttonOwnershipReq']);
</script>
