const CryptoJS = require('crypto-js');

export function oneTimeKey(length) {
    let result           = '';
    let characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let charactersLength = characters.length;
    for ( let i = 0; i < length; i++ ) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
}
return result;
}

export function hashHex(hexstr) { 
    return CryptoJS.SHA256(CryptoJS.enc.Hex.parse(hexstr)).toString();
}

export function hashStr(string){
    return CryptoJS.SHA256(string).toString();
}

export function hexToBig(num) {
    return BigInt('0x'+num);
}

export function bigToHex(num) {    
    return BigInt(num).toString(16)
}

export function strToHex(s){
return bigToHex(strToBig(s));
}

export function strToU8arr(str) {
    return new TextEncoder('utf-8').encode(str)
}

export function u8arrToStr(u8arr) {
    return new TextDecoder('utf-7').decode(u8arr)
}

export function bigToU8arr(big) {
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

export function u8arrToBig(buf) {
    let hex = [];
    let u8 = Uint8Array.from(buf);
    u8.forEach(function (i) {
        let h = i.toString(16);
        if (h.length % 2) { h = '0' + h; }
            hex.push(h);
    });
    return BigInt('0x' + hex.join(''));
}

export function u32arrToHex(u32Arr) {
    let hex = [];
    let u32 = Uint32Array.from(u32Arr)
    u32.forEach(function (i) {
        let h = i.toString(16);
        hex.push('0'.repeat(8 - h.length) + h)
    })
    return '0x' + hex.join('');
}

export function strToBig(str) {
    return u8arrToBig(strToU8arr(str));
}

export function bigToStr(big) {
    return u8arrToStr(bigToU8arr(big));
}

