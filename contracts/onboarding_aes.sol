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
        vk.alpha = Pairing.G1Point(uint256(0x1ab639743644f1d30480cc63743098077658245ce2b32d4c78988562ba7ab249), uint256(0x0dbf081c505390eca9ef19777f408ee107eec4485d2aa723a6f56ded4f123692));
        vk.beta = Pairing.G2Point([uint256(0x285d6f3cc3894ddb1311e0ba40433aeb21a33e884079b657419f3bc3cf23184c), uint256(0x2c0f18d61c86db6b705f873fa80b0eab1f5736524d0897fb5dcce07e61a585b3)], [uint256(0x01355ea94b2f8e0d345ccd3076a89734d4c5e9521c347aa48d9f7c3d921dfe8a), uint256(0x26e0b4b80831ce7c9ba21c331dd149fcf54857b3fa5d5c1316bbcc767b7dd489)]);
        vk.gamma = Pairing.G2Point([uint256(0x26c7ec90a4feb82d4378cfdb8a51a1a30c02766c02b9fce152427d61a3c80f05), uint256(0x107c3899b2c9c1ae5b464140624e574755336e0d99342fd7fde75d0ed22b43ff)], [uint256(0x0468fa7ae2d324e4310058241b2c05e13a264285c68cb0fe68c6df7f266aab94), uint256(0x05ca1d59c769e5fc77e022f9abb75e839a65d4a18dfe9e161d9bb401a47119db)]);
        vk.delta = Pairing.G2Point([uint256(0x2af7addca2742f1f5211afadd265444fdf77ffe710302eab73027f7acab3e3e1), uint256(0x1451c9d74439b1deea1da7416a63e6e161c019f13ef00ff9d94724d6372e34db)], [uint256(0x272dc35ff8f21943c3b3e68b798600943f65d439cd7d216ef5636a18f34d035e), uint256(0x043bea1a48e727f8365d98014a3bd08680b89e0466b8467e8aab1ddcb3854b13)]);
        vk.gamma_abc = new Pairing.G1Point[](10);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x003c7e6858ebb143e12f12af928a8c799582dfa6b36af996c938b35eab1282c3), uint256(0x0e7f33eb2ff42a793b2d34d243306cdd202b0d3f4b1917bf4c5d01b80024b946));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0057345369668e36e6b911dd3f406ad230829c2ff225441ad40d9785c96aecd4), uint256(0x17d061accf359305e0cbd16fcd54fde8a36e5350b1d08fb4031e1d3b1cd30314));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x066604862cea6101c184f20ea1c01cdad548a2872a9c69a6d741b169c5bc0e6a), uint256(0x07bfa824cbea9ca2272a1487e8ab3417e4b40e11c9d890938c5a77f4159e40f9));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x285cc2d13825382ffbe7fde2ee5d8d5e83c6a367ac39d500dec57325a6ffbe0c), uint256(0x07824a4059edd3a93d91c6ba88b926524cd7b964656f7cc539fbc571490ac550));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x115cf41e0677f5bae0a23a2598b6372ffe2f29ec955eae129f01fbc08138cd40), uint256(0x2033e8bbbdbf86c440a3bf60eeca9a7ddac4a6c3d9d911831bf5e120550c4583));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x115da6454be699dd01022cc1af880286bddfb0a3f2a0eede5e66f8f1be86249a), uint256(0x1305dde5ebe4e23bda8c6f8105caf1008f193df3879a755ffedd242517dab3f0));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1b6e85d4e395d5adfc232b8e4bca41284f6e22fa9801c5db6c02367998d1682e), uint256(0x2d1ca454dbe1569c8b0a8661da4daab4a45c081d683fec09152fbb20e07533c2));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x069dc51dcb43b51c43f4ec8f8f5913b0da351d47c2e040f58ccb4e3aca7b4305), uint256(0x2d675c76bf59e0e939fe1e4879fbf6ee83b7a983b804255061b5b6063667908a));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0b44f24cb6079d6010e9ac47999fd1f9b1ada991d066b31f686de57c87ef6a07), uint256(0x046c2f9ab6f93ceb19f531c1fc18d460abe5f533520e486a91a534d6620ed795));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2ee536116950fc537f05a2ba8edb074fb63582c3be251ed35dc5e1941d2df1b0), uint256(0x0f1b5bf2734205fa38f5b51e60e845a5f12b0226062ccf4be56f669f2e7db88d));
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
            Proof memory proof, uint[9] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](9);
        
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
