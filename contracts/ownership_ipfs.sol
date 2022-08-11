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
        vk.alpha = Pairing.G1Point(uint256(0x1b3222272b6a6ac09e71013434028f0ca66dc5db125452698ed9b5cc51cac630), uint256(0x15dceb47b9c597d7474fad020fcf1362a535c0dc7c91cabaa8ef76fcd9342793));
        vk.beta = Pairing.G2Point([uint256(0x0ebfa734cf8f993e7a74c9aa51ce6bdaa746760291bde3d14f4cd56600ce08ef), uint256(0x1003d999b9d5ce11da5647f67496fab660fc9753f463be4bf54288fd3b2ec326)], [uint256(0x143116c5e49bd56008b388ea361cdd4519cf6d69bede8ee3c80a5b44dbf27a25), uint256(0x09ab25c8ebca78a8ef0ba9b561d00635e5c43414290e8c8dfe5b374bdd0e41bc)]);
        vk.gamma = Pairing.G2Point([uint256(0x25f47ef65ed54358ec4033fe506f49682bd15e750deb8850eaceacc465b29812), uint256(0x0147950bd23dc7710bb585fa301b8cf8a01e505f64c1685e339412d9223bf29d)], [uint256(0x1c7dda45ff72052a19291de0a89a6a83cf8b02dc4fc337551760953e196d8910), uint256(0x1c00596699e0aab925c2e1bb9cec86072925f4dd6e1378cede11209188692762)]);
        vk.delta = Pairing.G2Point([uint256(0x101bcc201506ae2446fb5da8fa92a562f785b9c5759b346a3580276b52634d27), uint256(0x130327c33054bd264a50c75773a219746fe50a2dccc2840048a5f446051e5008)], [uint256(0x0d1cb33ce66a4f4ec846d3077bfc8138870e063c72ccb34ba4f3bd3bd98baef5), uint256(0x03f23da919c069a13a51ea45319216c34bed6c50f315d73bf54b87085a27bd9f)]);
        vk.gamma_abc = new Pairing.G1Point[](12);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x16634a0a2eccdff8059533a708bbbc0f3d6c04aa3ebdd134e393c126a2e0517b), uint256(0x30045f2a2912b629a985377857b11a2d5bf60daafb5eefd41aafccaf8799237a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0eb75e8f8486eb2b4f17281ee02d4329d63b10ca2b82608890829f3575c43288), uint256(0x2dae72ac41ffbfd78f9858ee4feb5f9636aa27c128dcaf4164ee6ac580f2d569));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x05becd5f1b3fe1a47525e54431731645d8f7fb75d7756d5ab63824a1fb70a074), uint256(0x1ddbbfc4fa03e309df1e50a0738aedafc31754f498f95608bbe465c52ac3da43));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0024601d86426929c64aca6e1f085afdf4898066befbf932e6a69476cb803c9a), uint256(0x05837ea184c79f5d4cf5a69854610591cf7c53923cb5076f59336853d21385df));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x039ba57036a0e9e3067079551f43db5155f943b6acf629ea9d5109973cf67c78), uint256(0x2af839af6d846515b80e027b1db8f3cb0444d4bba5bb5c521a6543a508009ef3));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1388ce6ebfe9b6d7d211e410a066f4503ffc1a6e164e41a1cb04a0db38ae1419), uint256(0x26e487a9645d93d570c722376ea781ee56a3b280e88aa2f96fa691088ba0173c));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0eca973cd5d537eeb3e25d3f0fc50ac58c9898c26dc984a20c973b746a5c660e), uint256(0x1fb5ccb4deaee60fa9d85ec1f48072b2c6813178f703f314120b48ef01b91e68));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2fabc873ff3393a42bfb3417e5a692c30fc4340dc1bbe9de144d2e83d27e85b6), uint256(0x1921ab9082575c147955fefc2f01d1ac3c4d03fd7924fac8065a1fbec2e725cd));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x01cf036ce5b3442eeafaa66cc85e655675da429414fe0c5a77eda0273f38a749), uint256(0x14178c35a23ec5bfa8ddca2527f4f90a9cc06e1921a891eaa9b4dd921516df9a));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x164691f362583dc979baa4c7184c63442e2d426a087a2c1f1d3576ae1be95538), uint256(0x0a4ec6257c42a34aa1180a31dfbd67024ba8c6340b61db909520e8ff17166b33));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x05c5022eb7e4382091f4b4bcaeb3050d2343021c92843d244c6997857f527ac2), uint256(0x2a74fe3ec432b14c74adf0fdb5d6cefa0f237dd170a7642822f79a788a8a280c));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x10d697307a73595a916cc9840922b9202a9ce080a26b581f16df1eddee3347f8), uint256(0x12696cf68ac3fbc95dd99945f9027b98aec58af8eb6439596ffb031114d8fb0a));
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
