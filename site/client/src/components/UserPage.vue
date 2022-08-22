<template>   
    <div class="flex flex-col">

        <div v-if="active.length>0" class="mb-10">
            <h1 class="text-3xl my-10 ml-10">
                Select An Active Request:
            </h1>
            <div class="flex flex-wrap justify-center items-center">
                <div v-for="(item, index) in active">
                    <Card v-if="item.recipient.toLowerCase()===account.toLowerCase()&&
                        item.ignore==='false'" :fields="item" class="bg-black text-white m-3" 
                        @buttonClick="(...args)=>$emit('buttonUserActiveReq', index, ...args)"
                    />
                </div>
            </div>
        </div>

        <div v-if="action.length>0&&action[1].active!=='false'">
            <h1 class="text-3xl my-10 ml-10">
            Onboard New Data Or Prove Ownership:
            </h1>
            <div class="flex flex-wrap justify-center items-center">
                <Card :fields="action[0]" class="bg-black text-white m-3" 
                        @buttonClick="(...args)=>$emit('buttonUserActionReq', ...args)"
                 />
                <div v-for="(item, index) in decrypted">
                    <Card v-if="item.active==='true'" :fields="item" class="bg-black text-white m-3" 
                            @buttonClick="(...args)=>$emit('buttonUserProofReq', ...args)"
                    />
                </div>
            </div>
        </div>

        <div v-if="submitted.length>0" class="mb-10">
            <h1 class="text-3xl my-10 ml-10">
            Previously Submitted Requests:
            </h1>
            <div class="flex flex-wrap justify-center items-center">
                <div v-for="(item, index) in submitted">
                    <Card v-if="item.verifier.toLowerCase()===account.toLowerCase()" 
                        :fields="item" class="bg-black text-white m-3" />
                </div>
            </div>
        </div>
    </div>
    
</template>

<script setup>
import Card from "./Card";
defineProps(['active', 'action', 'decrypted', 'submitted', 'account']);
defineEmits(['buttonUserActiveReq', 'buttonUserActionReq']);
</script>
