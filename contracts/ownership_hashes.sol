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
        vk.alpha = Pairing.G1Point(uint256(0x0a61997e3e69c68b24ae03d76ab72846d45510856e63b6e52b2b27e294b179e9), uint256(0x2b8aca28c87a1f6fa82b419f95cdf1147dde9e7f60d12d8155ea7619fb682b5c));
        vk.beta = Pairing.G2Point([uint256(0x2b9544fe1e1b01230f8dd32c2a4f9773a6988c6a81519ac749ca1c910ba7b069), uint256(0x0352a27668426869ea965324b42ef2d31fb284fe60ac0c3d028810373e485547)], [uint256(0x259eac983f165c69e61b3acb62d42fd6e82266178a4073df4587e80b854f928f), uint256(0x138090397d0f10e1a1d40440c6c4f64e1462d379f58df3234106c55f393466a5)]);
        vk.gamma = Pairing.G2Point([uint256(0x0dc6b13d9325070efaf5af59da409789e24c811342899afdcf7a2a3379e5fef2), uint256(0x076b2ecef3c6f55c577a61b36d5423ec9c826f68c1aaf07456a6d3b86c164545)], [uint256(0x256d87a1cf8e50cfd2ea00b0f43036554432bed16ba3ba69f841c5bb98594033), uint256(0x1be64e64b170c5179fef54aea067cad0dc6af123533d78d50a1d61d821f21930)]);
        vk.delta = Pairing.G2Point([uint256(0x00c64b9e111f3f12079303d2e13e2e61f81d3d355f4165b194793e39a8a86504), uint256(0x28ae496463f8af1aa862addddcc11792e02d87f609fb4fff2cd55350c7240129)], [uint256(0x00e0e2d3429d3767c19bb188f48a1fca9c4099c4f76587db18fa02972ffe7668), uint256(0x0605f2323b32235b453ef15b017fc17d7aad81119a4542f5ecbcea06f6305a30)]);
        vk.gamma_abc = new Pairing.G1Point[](17);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x294e893bec16ab23ebeaa9c7d5035a5125b41be2fd981ba3bff9900ac98407cf), uint256(0x14693e11b60cf75dfee2b6c5ee9622559d5796f66d890d03c446e7027b6b2e58));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x20b8d201df3b610c9d8ee59820a8cf86decf096f43c3f8e3c706c586b3c50a3c), uint256(0x2db8e4c13a7f25461bbaa6d7ea197b6e0d8d64a1c7854a5626b47acf58b9946c));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x17e26c59cef99bb7dcc0739dc9cb50e09703110abaefec89e9f02322c439d5ea), uint256(0x0ae65fbfd3b008128fcf8d7a8b23cc6efe2089075f7cba08e1d83d90abc28f66));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x00e0befd045e49154e7218b3ab87d1b2349b28f8b4db74d33469861e88a261e7), uint256(0x2ffd21eb6104b0ba9a123d2c507d39d40c3c8774f123c2f618df50de3aa7ba1f));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0051fcf6b937ad6112ec25adabc57e020c0ff5944b732713ac0bb7f8d0b86daf), uint256(0x202e27463857650eda7d3420174d0074ed4cf7c6492993c5a7e4912147d4ab72));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2e8201dc6481267b7d5d697216d215157ffc317b6f20ade146ac823726bf3511), uint256(0x26ba702caa22b410663e9471696c5717ede21fffd6486620356a602c2329eb0b));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2e0e0d95e3e4a3ae136f72715ee1b32978d2ebd218b725b3caae9aaf105208cc), uint256(0x17013b879af6827704479a8349426e0e90b0f1d480ea1370e0276c5639e6c095));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x120f1540031fbdfa9a36729d8dc04a5c19405e04c7ef579fdf97fddb1a4ae739), uint256(0x2ebb0bb4949f2df02905dbf24085c67264284293ee241a5d226a1d17c9c283dc));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x19ec5d20f9854c07097f15fb8952cf5ced4befbe8fe94e5ebd29e4ddfd999f0d), uint256(0x068d1505563ad4bb523ad61a47c8a78f3ffe4033acbd4d28e1b33fec40fff12d));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0e2872cefcd270619295f306e428251d7692bf2ee3d1750a45509b9be9cefc29), uint256(0x0d515c26af613d2989c401557d4b5e35a2ba5e9b62b896856b9e61382c10ea84));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x203c542953399fa4cf5b2d20acaeb738d726b38c7da055c1b1211e63626aa81b), uint256(0x174a832929de2ab958d95c6b7956f1ad541edb7d942d8f714e3155e71ab70df6));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0d3f66e889eb643ed67ce6c936c58111d0e937b6bb54e9f04ebeeedfcbcf4873), uint256(0x049ed457cefd8d208633d1e6ad57a7e6ffdf22f0d7d54d30c40be95d5331092c));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0c765f5121f11f07f7e6d71f85969797ac871bfb08c4665927361564958f575b), uint256(0x051ad8890cd4925134cf7ff4b076e83a03aa1c02f6d9d2a57f398fa1a0af3121));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1d2f0bb8e903b033f972492cc571eec86b1d97b45217f28c6be9e1a9d9b4f8eb), uint256(0x2a78bc81dcab1327884b72a45e9b9b725fa840b7b2369c8f7ff68aa919b2a966));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x2645bb0d3abd90dea0be5ac246e9738251be800e036b4cb6a47872bce58f76c9), uint256(0x26e6f5f074535a2110b3431674e48fc7544cd6f07de04466a1c085954d7c2107));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x1afb081cc91e5aa459ba625a878233afa09471ce573eb14a5623721e241a6850), uint256(0x2bb17dc29146814632cdb4ff8155ccd64c5fbcc92f9f37e789fec25a90575c26));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x27a0511ea570e8787f1f30482223d2548b470252918573473380121e2f0a2b25), uint256(0x156256180d9b33d324764c2d72116f28ecdcd29f477c22a919c904c593d76902));
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
            Proof memory proof, uint[16] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](16);
        
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
