<template>
    <div class="flex flex-wrap mt-20">
        <div class="flex flex-col basis-1/2 items-center">
            <Card :fields="props.value[0]" class="bg-black text-white"/>
        </div>
        <div class="flex flex-col basis-1/2 items-center">
            <Card :fields="props.value[1]" class="bg-black text-white"/>
        </div>
    </div>
</template>

<script setup>
import Card from "./Card";
defineProps(['props']);
defineEmits(['updateCard, buttonClick']);
</script>
