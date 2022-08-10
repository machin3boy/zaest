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
        vk.alpha = Pairing.G1Point(uint256(0x19e7e53d45dd01cb7425e475e86f8744b9d638ef0bac16bbb29eade89296499d), uint256(0x1d1c5f47375fbc9582e9e53b6f75fd5163dde6344bf409328266e7ff421f4030));
        vk.beta = Pairing.G2Point([uint256(0x093ae0378522fff288c9f427ecdde7195923043142f4a1e71cda5dcaffd6786b), uint256(0x1a27ed28bdc3ae0717d470130df2b7c820e0ced2b90066903566208276ccb869)], [uint256(0x15ccec2a05a7f427a240bd96b6b763664a2fd09ce5372661941d5843f4d7ab59), uint256(0x1e535e2ee124e2c32dcb02dd2fa8cf2b4825fc81718dd0c486074d42f7d4b603)]);
        vk.gamma = Pairing.G2Point([uint256(0x1b230408c45632751c9b15c44528714fd7c0de86b25d7cbe0e9d1513a0c77438), uint256(0x1e67b24471b12b63178e2c57863b29fb6fc53ec57dd1ef156e1d762fc5ae92fa)], [uint256(0x18e0a3a0a30482f046aebd2a4faed9520e40a15255c764e12ad0cea45eef976b), uint256(0x20bdc3f6e4474dd3041e7fcd17244850bbff117104e65477d3ad377b4ed9662e)]);
        vk.delta = Pairing.G2Point([uint256(0x13536c06b34fefec4ad7efc1ffbeb23f3d02b0fdf353f5bdcadf57f5d4a77bbc), uint256(0x17c2e337997c45b3d37c2b421a7d4c57fe58030d50cf25886b6f9ea9d9c83dd9)], [uint256(0x2c73813d52217e6f9cc1b304f8e35e81f0826343f1b1cad2e741f00004315515), uint256(0x15d60b868724dd5387c7d3b0abd4ac3e98df2fff742f0167ad6cce7d5834a705)]);
        vk.gamma_abc = new Pairing.G1Point[](19);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1c864797327bffbc1cb8fdf57471f212417ba6dea22687ebd9a31e265a6ae011), uint256(0x0b7d6e8dba254b818bce5dce19ad51be1c4d481f47b386b129ad38015ca1d922));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1e675ee731f9ff9b4f233c428c0a9119aeb0c3f5d8f0f517023f1c2c333984f1), uint256(0x2c3bbf45c741b5da5dd18e9bb7ad590b8add02169df46d0d50990221bbcf4692));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x06c5b5ec659598484ca75f40d4d03fe23888b40a6add68ee158ac3711b8cf1fa), uint256(0x2868f9b92fb6d6c3b28481d44337fcbfc80fba102450b8a640ea2a4f06d5a7c9));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0a74e525af4fca8b9915f703d3fb506cdc937d0509dc466bf2fe4c0e13467a94), uint256(0x2bfa40a076a8e80861e2e5c33ddbdebf1cbe971723ff1a93e8d87bdb95a58dbd));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2edd80c9fc9480de9c6d285255ea2260ecea6d5542a251dc3c23ef636dad5521), uint256(0x15de1403445751642e5bc93b3d01297c37b14b9ccc799511c60efd4460655ddd));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x03b7e4d3563a1f5216cfb3bcd263c6f6f25d3ded87a379b115b9ff616413b97b), uint256(0x0040b1954c079f2c586d828b3d2c66d269f2c0d86cb542199c7ff8fc537346d3));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x00e84f27103819f3eea93e32172b394ddb96fc803698bc2f8ee1138ebbcd7501), uint256(0x2b68d2f1e51441d8eedcf928c2975112ca6ba108c9ef8effdf2c055351d4019a));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0b5b88920e4360c06d76f2ce4589d81c2ec8d06ab73cee559c0af8c2c869b724), uint256(0x0278da25a0c12e717f41dee8e89bf90ae4df224832cef363f97c65ded8fce243));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x13574e8841fbe545249c251f108568a9ff7f651fff47eb0dcc99e2027902ccdc), uint256(0x0ad7c4f6596d819245b8ae5525b6a50664b138270d94cbed6ab6ee45b0c4e222));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1912043d108c67140960db68300053ec02e3c1a6123d787c65c4ff13c1a64509), uint256(0x12e8de85c6dffbc79c00591eb38a3cf1d271dd072e0a7894a977a6224dd8668c));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2ec94b5448cc8f3e0b1f6d26fdb763ee7a4cbafeb7476c3e7cdb19e36199078b), uint256(0x03b316adee0e2dc5712039297b54116d34d8e42b2683bf2f6f2bd9003a2e8cf2));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x293c077948598f5eea42442cd641322733bc749ebb793e740cd4b7c87e3347ab), uint256(0x16dface238e4913294e1aa696652e261626885dbed23ae1aa272b30d052013ab));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x056f03546a32693e759eeef9fa900e9da6bdd8b9d2d5ebca10c3f48cc151537d), uint256(0x1fa192a07f40940e00ba1e531313b4c473a9e75b655b0b5bf3eebb88416327fc));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2d0e86f1aa9bbdfa66c357f9a655c323ac1c78edc336d5200e7b68b6673fd28d), uint256(0x0ad11a841c50f73b77fb8846fb200dd59b40675611706ae14551a468328d7ab4));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x04e858e1a2b013ec8c0c9038eda20ad83e79cf0130fe224fcef33eec9350449e), uint256(0x2a3fd76e26264ed45d1251c2c22874ddab9548737a60313f6967a45b0b6c357a));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2bbef2601ea0e65286305f791271ed9383a97751ab31893774b7ad12941047a1), uint256(0x06c20669c0d291fa5d3d49c27906ace5196887b3cfd8bcd758f80a508ef6ddd1));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0cd966ed5d7a5d2eb6ecaa79828ddd8abde0b05238466b8cdb7b7f1e5651ed5a), uint256(0x05d5de5de3411e3c857021ed0d03b42e5a8c002d9783a4c0d5a044a979a9c25c));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2c117750cc2ce1c676c6ee95916afb3ce0e2f4a05c69b0addb4375cb2176dd26), uint256(0x1671cbfab4315e1afe4ebade4690f360cfca697264c63da9c87f67e16d7e13d0));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x296900cb16fb07345f8f7184a14ea5d7e5f10bda197bf9e0623b32d6c1215228), uint256(0x15987f8696204091a4cf8099bb326995ec358f58bef9f45273316cd6cc0ef13d));
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
            Proof memory proof, uint[18] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](18);
        
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
