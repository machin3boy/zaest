// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x18e4d3647d737667ab0d72dd7049b6fe54dd4f6332b5a7cddc3ca9fbc8d0cfa7), uint256(0x07ae29e73a031bf9df7cbba213cca2235cd21a7b8dbfbe57e306dc9f89853e59));
        vk.beta = Pairing.G2Point([uint256(0x152e24aa09ffd5207f51f6acee4b3362b6f287f160922c9e779e110163c8b110), uint256(0x039c7b445de1b3b83c6c424fa0b23f5c8149c0116598f3a55352e27914eac5d9)], [uint256(0x08d551c550335214b17875fbaf734a557b78474bcceb47b33d2d9c8775ed327c), uint256(0x26aca89912933397803f5e474772256a49f465ef96a7702e2018d72b639f0332)]);
        vk.gamma = Pairing.G2Point([uint256(0x0051fdbdbd8124afe1b4f8326c428ef2f26beb0bea9e5e703d1f01a45d3239ac), uint256(0x1f8ccc5e85aa41dd8f39c7b4d27fc202d75a6f2145777a64b573b4263204c263)], [uint256(0x2ff37c94b0ad7fb25287a806ea1875f68b5211ca584f0203fb34b9c72aee664c), uint256(0x007e7a9bf0b70990015feda490c8b41344e2d4d3783727dc25abe3b102c47900)]);
        vk.delta = Pairing.G2Point([uint256(0x21261dd47f7b5ce690fca9a085f19f40eb1d7c88c3547418bd5ab1db0f68ed12), uint256(0x0af0e0f7c941b39c96bf70fd1f0d8e2605a760e7c6d3d4bde90edc422f840724)], [uint256(0x1cb4f080854d2729c0588ec1e916762d50db6442e278b4a88f8bcc4e6f53b6bb), uint256(0x09840bf7f0f9c73faa41c414402939068abf3b6c5cb8fa4898d3484da42755d6)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2bd14af590b7ffd97fda685cf51ab5c25f44a33aa9b48f3dbd717a324f44d7ec), uint256(0x2083e658806641529c24c5e3cd3f036bcefb8abdef312f4a805c7d2b289cf5e4));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x28006cc142a6d035010eaf9d6bf4065337985de48e4d6bf12d2925f78dfa2e20), uint256(0x2e65bb88ca63d043c88a5fbcd570393e9cd0ff565bf40ab1da3e32a892ada70a));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0d29e2c25a1acb56bca1ccfab466b7725c60a7401f94e38ef33cbd06c7f10a4f), uint256(0x258f33dadc09171be62ab75f066aaa78826b787c8d93ef56d21171f4d6b48854));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x299e9c434033c9a18c153e6f8768b4a6f723561d748af0c0e9b6705240f63f14), uint256(0x2163f214bb14413f6573057252561c6abe463a006fa6ece266f1cd09b41a943b));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x236950a8b5e3654157681f67dc533b4b9f125b442f8e810642f19bb486aa183b), uint256(0x179e3082d1ffd8398c2db912306696daa4c88b9fe46c85e6e22a66b7120093a9));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2f7f35205972d2cca5742bc77abfe76777052342cd0f81b77261aecfbf6dd51f), uint256(0x02b39b56c28d192536920e4290b2c1bd4171a03113d041aa0f0cc9ca40690573));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x035534e6e900bfaa9d485a24b9656e4c732b98d95997b3be7292e28a1e476b42), uint256(0x2ac74eadbf4168d2917a3ca28ebc11a8b6183f15054db34791122ec75c4f9087));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2acf802488026fa0f59929f4ebcc86d4efaa4b90064b4ca8e0c768e91e320197), uint256(0x2fc74a448e63c6114b75dbc2dd152c4860d37266caedaeb3156207ddcc463c3b));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x191c34d6d3541f9bbeec641005f0f6e34274d0e9860b12ea62a5737bc7d8b527), uint256(0x2f735dd5e99210b7f77e02254fb71f7f72a43b75fd89c4da91c8e22c49942fd4));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x21c801b918d028e9f97ef75ea06196b33faa57932d4c8e251f6439c270ab1e4b), uint256(0x119ddc1f57b7482a105217c15821aeae0fda5d1ef635bd4a069aaf497264efdd));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x24c9d0baea2a448515712333ee9695cc66ea810f5f5f7727cc50f70ee77dd433), uint256(0x08c61395f00da1207fb6db9662c32ee4252473694a812c0e35933d8767835cd7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2075251a9bfec596dd911a77a45867765031ea91a43a35aa5ad77a4823019eac), uint256(0x024e5c24f4f331dd6fe4c25ddfa1ba4fb8dc3d5c119ccc5be73fc5e2e5dd6d5f));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0d9a1aacd92567b10ae4c7bbb83e708830d6042273d76cdb2bfa7ccb122482f0), uint256(0x01e5fe78c3ef577fb97e6b3130b7bd7893a2cd4c57b2b3d47f545ec7c0d06d0a));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1b3b23fa6b8e7adc198fdddefbe6eea997c0a5a2e37b17c0890a8ee02ffd377b), uint256(0x0178c2bcc7603e1c7dd7892a89d245f5388a907346dccece202c0aec18f26d8e));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x2a85e84862f6a26ce0813d04dc981989caf5c5a8ef7afc215563a245dab3aa08), uint256(0x0913400cf4ff6527ddf62e5db90ca4861bfe8d1142b6c7e082f83eb8222f653e));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2ec638345f4211dccd60a178ac4f38d69057e22b5ac716be0db34c8fd64171a4), uint256(0x25ecfbdc04b78114324cecccd1948c46aec7030581d8cdca634411c1f9c87ae0));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x1c3e5912370659cd8fa8210d1ed672cb85c694f06c712c83e9462ee01d174c2f), uint256(0x08550914b65f522f1238fb7a3bc91f8c1a8c8e1808818c7214c7cb85cb3aae0b));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x0df865d2f7cea3df19f964993397bfabd1ce2f7d776df63a53976193392006da), uint256(0x117ce90bebf14bded3c7e05e223795c7cce1776b40c875a2ed6ba6c125dcb703));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[17] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
