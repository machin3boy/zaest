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
        vk.alpha = Pairing.G1Point(uint256(0x2f83770de85f0fe7305133c00d89b295af98ba8c98945c9e6d65ce9177e50e77), uint256(0x2f4c7dc78d36e7333d56312c27d8b57dff5e1feebbd53425da7d9f9d85d538e7));
        vk.beta = Pairing.G2Point([uint256(0x13fef9fb3b3e1e795d5cd5afc7184c2ee4fcbbc45b6ac616b620b7342cbcd8c1), uint256(0x2b26f1a42d4694ef7c1288224c11e8dd3a25cbdda24d51d37026d4db95b8156c)], [uint256(0x28146da918ab8f05435099c0dd7c9ddaed421d6847c9ecad8fa3e272b964af87), uint256(0x13ea47e121be3499c71bbcab064e95fa373a90bb22f90bac6dd4677dfc39eb76)]);
        vk.gamma = Pairing.G2Point([uint256(0x0ef59eaa920db0967eb5b32de09c83662c6a4db1b159e2c2e905794c1b2addac), uint256(0x18f065ab12eb5ac861ba980a24580cf558241c9ef5bed42b2bf4e93b8f740649)], [uint256(0x0811e507ceb1a9610f32af108f0b889c1f154c25016ef2ba07964d30a09bc114), uint256(0x2e5ab783c93947f30d7178411c7c3e859edbf28d019bf75a04a42423571c9bfc)]);
        vk.delta = Pairing.G2Point([uint256(0x0db7cdbbdb940579ef185b1a34157dd3565757b197f207f09737e79e7948d249), uint256(0x0144d53ce0668d247262f02621a97734f1ad57ecb09a66b09a4cade95d944392)], [uint256(0x278805609d1c6174a5be53d16b6f02921569799dc0c9c399149f4a3ed69cb041), uint256(0x1c930eae1e294654bec48cd1d8969db49832f7e7eeba28e90efca0cbf278a0fc)]);
        vk.gamma_abc = new Pairing.G1Point[](14);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0986ba443920be22c1cc74756e20795f1fd69043f00a0f9f71f32f40e747c2bd), uint256(0x0b460b2219caf2e7f3d9836fd26279a094f4f8dfc4c5f4e0e58f819cf875bbe4));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x070dcae7849eb0258feb1d59af12d2620df483d55e11dea8960f5b0e2a289573), uint256(0x27c93dc6002e973248b11494183c3e56b8123d8bc73c638906d57f265197fb74));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x148ca7bacf7acbce7324de4194a2d2c92d86082ece0f36b67eb6ba039cdecce4), uint256(0x0593b08b0c3691a6b02c11f89d584662ebc4cfeb3e51a07eeede4cbcc46084f1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1afd7bf99bce8f326dec89ca186d6b37cbab9d473ca6406e091f0f7d94b95412), uint256(0x1970cbfa03b2f58d0ccae7ceb2d2d849f98b10ed5b455ea5b8296302cfe0de2d));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x03c480651cfd0fffc77d690e946f6c63aaae687c0a159a582b6d075814a1d9e0), uint256(0x22aec7aee3dc0e50cb721aeac85f7daa8474a9edf8df76122f9827d755a0abd9));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0bbee4919d25542f3e3b16b1163ee1bebd00e63c21d68f4d97bfbc3b0463eba7), uint256(0x15a193bd078cc9f8224ae25a5b5697774946649d2cc9a723809b64b6bd71c163));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x241f49fa328b75ffba916d05aaeacedaac61b0a5e1ec10f47387de8574fd12a8), uint256(0x0ec61155d267a25cd1e31060e3716bb3854c018464d9a387cde218ffa1830472));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1512db91d6e98ab89a61699ec4c2056ecf3c03b4bfef46aef6465618b28a079d), uint256(0x2131075d01d1956a1bd61f502f31b3147a7740773055b83de3349066b5272655));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1d515a4212df9f6a75812c133dfdcfce6bf6490bd0575e8006e968f4fd62eeca), uint256(0x10d01050420e0a86c678a8784b4f418fadcf3b70ca595cd6b80f3069b18c2283));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1d2e8b2f7cb592030d31e0e404e65e5f170080071488901a0f17b68876bea2b8), uint256(0x2a68357801658ee2b7b3c3caa083ceb18d5936afd9ce0e5850475e90884e1b87));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0be583ce6c111217ceec284100d7b896f87e518b39bdb21c1db5b44952b40b88), uint256(0x2ad126923de6a012d68ad05da0dfd5c0fcf172b5582922e69d08704d3104f0ac));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0313d3f3ae17725166665bbc76525adb484205de80a9ebb507803f4b8f75a2d8), uint256(0x0596d0caab8ccf61ace4d4a832d0b03ad92909ccc41c7842e88400f864566a56));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x2bb378d755a4a1e867d5b66d817c1cb69b91ba52794a47d46e2a62b29dd2671c), uint256(0x261c2e3219659dfb424a036750701150c93ce79c1946aff13c89fd818304a76e));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x01143a16a2156fb27a90ed2ceb179d472ac73ccfff81112003ee8b253d508795), uint256(0x0d7fac715a0ec7db93713df5699042efbe516f3b707895b119f96dc16c3bba31));
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
            Proof memory proof, uint[13] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](13);
        
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
