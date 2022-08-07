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
        vk.alpha = Pairing.G1Point(uint256(0x0a0fa859d442f03047725b5364f352a6c4b780c13ce0f198fc3663210147aec2), uint256(0x0981ce39bec9089a71407a2548c3f3083a74b7e4e8abd5983dc0695febecac68));
        vk.beta = Pairing.G2Point([uint256(0x12f3715612dce6fd325da8b26640907660b83ac6c5e131b0d95356f883ae62e4), uint256(0x0cdbd42c8dad8b5df1fa3ce93faaf3bf38dcdbc37c7005ac0b6df2cb27744a7b)], [uint256(0x282b3c67e2aeb13f7ce697b41eb8c0cf0bb5986091dd05ba72b2833bdbf2f750), uint256(0x07f9b8d71756dbe6ca2c99771c1f40e6dfc7c5fcb1e524b7148e188819ddee78)]);
        vk.gamma = Pairing.G2Point([uint256(0x127e779e4c150b0bbc047be2786b0648ec5caf7bea456e539bc1c97aa8928cba), uint256(0x1a6417188b1dc64d6f999671d7d987945a9d1ab98b3069eb7bd80efe1bea6eb9)], [uint256(0x127fb06d0faebb9c7043f0ed53c2e401103b66b18813210a593d04879f86dd62), uint256(0x284be0710686872a038862451224dd2061f5ac15aa9ede0cc844e0693163b0a9)]);
        vk.delta = Pairing.G2Point([uint256(0x03c296fe60bfb8c52e25d74c75745c0bf8261773ed435f7a988a1b24cacc07a8), uint256(0x16fedc1b578e5c6714a990ba69c62b2f689ff8851a7ad51fc25ab99dae412b83)], [uint256(0x1953052c2f7617487b86a9206201558aaf562e1811e69d853f96d8c5c31057d2), uint256(0x103272034c2bebf69fd7997450e609244d559c8e3bf3973528806d414ce7657e)]);
        vk.gamma_abc = new Pairing.G1Point[](12);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x296d0d03254f03c253cc1a2971974ae1a3b621a20a267cec5afc8800fea86f32), uint256(0x0c8020777534fd22ee6d21085939d38c995a931d5e4a042ff2633b72dcfe6474));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x06a7ba7245465ec6e587baf3640aef42633663c1760313c5fe23b711e007b1c4), uint256(0x1ce8ccd22423f499780d5f662d67e2975f2ef7a8fc248e1bb0162d9510759eaa));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x146a1a5d37206c8f69781f0f29ed4331a974d10a74fc62ab0f1438606c584e0a), uint256(0x189392cdfd106e970a041365799075608f34d02734d952453e3f564715bf05c1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2f6ce393a6390b299aaad573fb0b04c9be8d6053b6e8c1088eae6ff11f5184a0), uint256(0x1124ee7d0e00cd9d6a4272f2e51c21dc62493f376e76762433fb28144893ec55));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x18d1f56d6a97971c5ee22aac102abd23b18ab301fb086c2203ce2af41886ebbe), uint256(0x2fc32c61f1f2e3bb80c9d5b213303a0efaf06c87196ca36a3fd3a275ea75b5f3));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2edd9d02ad99559c8d60ad59d07a2257e7277facf33f9caca798b7e1c401fdbe), uint256(0x2d2c6740c6896aab4395cae4029a1ff5780de3c1a6bb7af99a940ca1da27c7bb));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0c043705b8becb681f46121d7b5a3a1e6e8e8e3ae8ccdf1bb8d3a43d1c990582), uint256(0x202d69053dc355dd10d245700f93ea270db3d56117dbed07827032ee374bcea9));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1426eb96bd6fd6a6b9b60b1ef959ec9f77296f501e492fee049230657c7b3d64), uint256(0x15a9fe63ae8639edc924fe445bb85baf41af49a6a04b3683f491c578efb0a01f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0fa46cdf3922cca6f7410af599b4bbcec8dc533bee629db2a0c2904bb6eb4713), uint256(0x079d41d92e99ff6817fbce4f52e4b7d851e6096fef1f1b513bb674aab674ff65));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0fbe466eb98473c8825e8ceae0c2d10c0ea550ac2d1ba2a943f2874a7b4d75f0), uint256(0x0aab236409175c24c62c4b99c66a2f96ed9360342b55b7c9e02fb784dbc9685f));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0ced02c82f0f127586408e6122eda9e3c487ee52746dd29b8acf327de7ef9be8), uint256(0x02243884f9612de2ea0b8b36e10637b1ebb8d85f2ded3dfdb8a8c72efb0b2482));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x14c5d409aa81ea100aebda7bb2bc8868d35734029cae1adf5d63461b8d69f8b5), uint256(0x15ede7f17701cdb4d0706d30eeff05e020baf10b190f6398d2630ec6a6fac6c2));
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
            Proof memory proof, uint[11] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](11);
        
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
