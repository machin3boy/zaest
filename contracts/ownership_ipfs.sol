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
        vk.alpha = Pairing.G1Point(uint256(0x0c5b28945bc202c04bc4d401dc708727477518c35240d105e5eba7acbb68a281), uint256(0x04f2e776b453df9bdbb2fd2b90a0d90db516768d959aacd3499dfc42f8c0fac4));
        vk.beta = Pairing.G2Point([uint256(0x153573497b6795aeab06127fe1454b735f0c224d121c739257e922e0913bdebb), uint256(0x169ff43b57a01a20153a1a2ff7fbe99a45825e1cb71ca9e8c46b2b4f481f0a19)], [uint256(0x25bcf7f110f8f71270064dbdb9b8e14bbef08b804c0f72dc366249efc9ce6feb), uint256(0x05a9c6cb87af792e6a1883ddfced561becfd99d9715e51d963f6de5494571566)]);
        vk.gamma = Pairing.G2Point([uint256(0x18624b6b50e6c31656d92ef3172e28f6dfbbcd0db1e487425d52932921c69b1c), uint256(0x2b233cfd490d1033b4e0559e518b38203ca5d215e0671bcd60f93a65b8c5a901)], [uint256(0x24cb9813313cdf9f73cb9b775c1d3e546f2c8a4a39f25ffd0debd0a3646793ca), uint256(0x2401819f6c6b97f407f3fdf9753451448d5e94489c12a3a82ab9ec23f934d35b)]);
        vk.delta = Pairing.G2Point([uint256(0x1d0313dd4f67e512e0466b87b2efb12a0a27ae92758bc2659a489758035f1d42), uint256(0x1d91271e772f43a64ad0da672e9f95dbd86f81b0c04224cb86296d6cae51e295)], [uint256(0x1f333df985c70e5b25583d27a98e3e76387c37e9fdebe175a1f31129a367f7f4), uint256(0x0a069fee4dc220408a70d9aa1c0f8150079b19c7232d2a3e2a2c658cefccb70f)]);
        vk.gamma_abc = new Pairing.G1Point[](12);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1a87a53e3f0365f873ba75155cbd5c679ac0084171fc8a343b19fbf6e12f533a), uint256(0x03a64fb7dbd6a88cd8355c466fa8953296e5a4a92ade15097e4f687e9a31f838));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x22f1c772a7ac74637d25a9de07995c0b934a9c134c2008c4c70860e7344c4393), uint256(0x0657ea109d7196026c21df199535eeb50f1a16187fac06be32d891e031ee0f41));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2e755d4926a384cc5f54aa8e77390c4d61e9b079baf2120afc757fe0c8fe5838), uint256(0x0037e1628c0d8e27c418b4c8361a07a09919aa67a0fbfe70816caab5f413c626));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x03c97d563c77b2c09fc4c1a85dcef9bf91d44100efc1a65cd6a7223c96009265), uint256(0x09ff52340a0560fbbe0837245ef38a78848a1949c48ae63574654af7432e6a5b));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0cb53a9d2b45e88f1c2acfce4093a2d71e5f579a9fc2a463a67f0003db457c77), uint256(0x1313d8f0f52e94cd65609680a6edf50f4156dbad5724831d98ecd46a4ef3e6f0));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0ce0beb60820d8425e16a2d2d1201324d99965f0c4d1ab5e6e9083969afa26e7), uint256(0x304efa90c8216047117654874dccfff78e0b201dc528819e2eb574d0a87eed16));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x033849beb5c6ec73bf5b38e959f200137a345119738699b2a9dbd38d3e8eb423), uint256(0x28eabd9afe4868914e2b683870eb8e15912f1ed3a67b4b782a5f6c8331c45bd3));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2eb56ea9261a9fbb4f594232be1b408da6d051387333ecd1426ad691d273dee0), uint256(0x257182304864b6f8b3beb05b9ba34e4439abca76202d42efe4bed00de0a6e965));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1d9b6f944955deba804b98212c9017147b6d9d22a2842d5b1500bf4e0f66666c), uint256(0x1a38902b158747fbf6ceefa5ba966512343b05c5d877eadda84b9049310ac806));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x14e72a68241d570deea8a0a564431eb7858528082ade6e85c0b5a65fc959bf74), uint256(0x19d79384c75c3c5a07f5feaad7e7cc43483ecc44fe0807a4db8ac714df3d5d2d));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0f08bec31785ce97db4cbbd10e68dd8dbae47392647994bd4c4c9120e7597ee4), uint256(0x23f9e9d9c65fb087ed46be1c165115803d57a32dacdd2ab05f3ab73fd8150f5b));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x13f4b665ab4048bc600487a837f4d8fda9dec4ddba5ccd5d3c742848db77d2bd), uint256(0x1a59a085eac67e2597184b1614a83af7f4fa7b916ec3332dd91d3aa596c3864d));
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
