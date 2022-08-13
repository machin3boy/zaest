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
        vk.alpha = Pairing.G1Point(uint256(0x27afb926ff433c26b17bbc7e79789e5c220fc47c4103d370ddfba89bc9b3e676), uint256(0x27d500b3c49100591a3645168353f100208af05b44d2c3b0cfc5be6f3f9a1708));
        vk.beta = Pairing.G2Point([uint256(0x261c6239042f50fa42a4bd73d3c0dcd693af853e1dfa408045882453d4c20c08), uint256(0x05466387e46b369e501c9e42b78ed8d548f191a1205a09eca9ed96987cae5f1d)], [uint256(0x01433422441c2d91fc20a5facd070443745b87f723ca3e5e2b26c7edad17edda), uint256(0x06ba3e41f581d6c7fc39e579bb8664f78a829c56289579941676ddfe85628ecb)]);
        vk.gamma = Pairing.G2Point([uint256(0x295529294b8c8c9c7a24080f1da508599b1931d6199f7f104ea17d53f6e62938), uint256(0x2c4dc0c4a5f40d837da750dd7f691dc090bf6158451c52552a654f0ae6a52124)], [uint256(0x19db8f47f442caff3d30d76427811be699002985b730f781543a17dd632e360c), uint256(0x2c62c42686031796126eef698998b21e9709098daf4f1eb61156ca18c55a8a20)]);
        vk.delta = Pairing.G2Point([uint256(0x1a39741e25f504f7f5dae52cd790beb002bb9fd65c64b373b3a8d15d562eac1d), uint256(0x266dc319634ab678b5ca55978ffb12567c74bd7841f91d655a8bbb7d2c62a464)], [uint256(0x0d074f766c6e6ccfbe1cb24740e385a446a352a6a7eaa8a73d1f9c9f75dfcf0d), uint256(0x047133d54833bd411e7e5ce56e440f7adb05e68c17653d2645471dd23928a827)]);
        vk.gamma_abc = new Pairing.G1Point[](10);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0f94370c9d04ce6c368b3fd4fea6b8cf0a1573126400ba8dd9ab469b59230d06), uint256(0x021513ad2545aeed55e28f0abd5fcdf158550f3325dea67f0d33f3737b951b72));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x230c177e0e9e9764f1b9091b5ef667ec206c0f3b190f31e6f44c71b45b804ee8), uint256(0x12ea267eabcf86354e453933d4637d96ec867b686cb9981c55b66136730fadc9));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x035e336e808cda9391da106cf78d1310d0be6de0782c9feb8e13913913454826), uint256(0x2915c706f086c1704c7fbc4d5862d65fb7eec34da5c46fa8e03b4d67920a2a00));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x22149bd27e4dd3fab30ca2dc845377ef25a522441eb24887a2428eaab64e154f), uint256(0x301039483d134cabdb09529c260fdd43f918327f3440fff6c28513736847aa4c));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1f0892dae296117a50e43ffa0d923eb172a79dc91295465bdc5b7a225a187c07), uint256(0x02a751afbebf7acfd1d508c460c64715a4adba560862e0d86704bf29af993984));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x032278107ff62aebbce506856bb07529eda40f3836329b307a90175cd3988aa0), uint256(0x271ddd1fa3c6491d2c30e1aedb6705b6165cc17e1515f0c725f4f7f3b123e591));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1154bcb8b3c271f7caaa283184c26a5ff7e80cd7dde61ea885e29248ae0dbc18), uint256(0x2d60c09b395737d7c89194dad0131ebbcede64183ee90446ae458fc236010777));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x303a976e5e0bada6facb610c5ff10825a52238c58b000772eeb0539184814ce9), uint256(0x0e5bb58317f1efa47f9b1c18f54540245675713bcdfc03f673def0a58c7605e1));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x290b1b4bd523b12ed492f4ea89f57edc50d6b2661aa889ed92520fab05dde2d5), uint256(0x283fa7cc441cf9d9c7b882a1a402a3544693e9deee59672a66306a17d4235843));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x25ab1c708f975c8c878dc45e816b0f1b5870e14f456c7e1edee2397236796058), uint256(0x10595fc1a44d46a7c8a4be87c9083441fd7b1999e247a4c1adb7f69f5a9bdfc4));
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
