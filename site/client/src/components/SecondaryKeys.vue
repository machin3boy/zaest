<template>
    <div class="flex flex-col">
        <div class="flex grow ">
            <h1 class="text-3xl my-10 ml-10">
                Onboard your secondary encryption keys: 
            </h1>
        </div>
        <div class="flex flex-wrap justify-center items-center mb-20">
            <div class="flex flex-col basis-1/2 items-center">
                <Card :fields="props[0]" class="bg-black text-white m-3"
                    @updateCard="(...args)=>$emit('updateSecondaryKeysAES', ...args)"
                    @buttonClick="(...args)=>$emit('buttonSecondaryKeysAES', ...args)"
                />
            </div>
            <div class="flex flex-col basis-1/2 items-center">
                <Card :fields="props[1]" class="bg-black text-white m-3"
                    @updateCard="(...args)=>$emit('updateSecondaryKeysRSA', ...args)"
                    @buttonClick="(...args)=>$emit('buttonSecondaryKeysRSA', ...args)"
                />
            </div>
        </div>
    </div>
</template>

<script setup>
import Card from "./Card";
defineProps(['props']);
defineEmits(['updateSecondaryKeysAES', 'buttonSecondaryKeysAES', 'updateSecondaryKeysRSA', 'buttonSecondaryKeysRSA']);
</script>
