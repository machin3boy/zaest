const crypto = require('crypto');
const PythonShell = require('python-shell').PythonShell;
const CryptoJS = require('crypto-js');

const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", {
    modulusLength: 1024,
});

function generateRSAkeys(){    
    const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", {
        modulusLength: 1024,
    });
    return { publicKey, privateKey };
}

function encryptRSADataPBK(key, data){
    return crypto.publicEncrypt({
        key: key,
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: "sha256",
    },
    Buffer.from(data)
    );
}

function decryptRSADataPVK(key, data){
    return crypto.privateDecrypt({
        key: key,
        padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
        oaepHash: "sha256",
    }, 
    data);
}

function encryptSymmetric(key, data){
    var options = {
        mode: 'text',
        args: ['key', 'data', 'encrypt'],
    };

    PythonShell.run('./aes.py', options, function (err, results) {
    if (err) 
        throw err;
    console.log('results: %j', results);
    });
}

function decryptSymmetric(key, data){
    var options = {
        mode: 'text',
        args: ['key', 'data', 'decrypt'],
    };

    PythonShell.run('./aes.py', options, function (err, results) {
    if (err) 
        throw err;
    console.log('results: %j', results);
    });
}

function hashHex(hexstr) { 
    return CryptoJS.SHA256(CryptoJS.enc.Hex.parse(hexstr)).toString();
}

function hashStr(string){
    return crypto.createHash('sha256').update(string).digest('hex');
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
  var i = 0
  var j = 0
  while (i < len) {
    u8[i] = parseInt(hex.slice(j, j + 2), 16)
    i += 1
    j += 2
  }
  return u8
}

function u8arrToBig(buf) {
  var hex = [];
  u8 = Uint8Array.from(buf);

  u8.forEach(function (i) {
    var h = i.toString(16);
    if (h.length % 2) { h = '0' + h; }
    hex.push(h);
  });

  return BigInt('0x' + hex.join(''));
}

function u32arrToHex(u32Arr) {
  var hex = [];
  u32 = Uint32Array.from(u32Arr)
  u32.forEach(function (i) {
    var h = i.toString(16);
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


