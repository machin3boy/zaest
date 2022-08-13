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
        vk.alpha = Pairing.G1Point(uint256(0x056b68f9055b59920dd2b0c0825c15b2c47f9bc30895b3c5cfe912e34fc2899d), uint256(0x2e3e83275f7fe16473ecaaabb44c9003b728be20ca8fff947ae93a32f5d54031));
        vk.beta = Pairing.G2Point([uint256(0x2d9f1b71c017f4c5f38dde3c780fc38491ee62ecfd96517dd56df44589c8a1ac), uint256(0x06430b6b27c575a09b5282bc152049168e7d16264c20718d89eff40df92da2a4)], [uint256(0x035a396c31600af49872839605c577a34ba2517a64b13255195d0e65ef4f7778), uint256(0x21dc5ea53d92326347ac8deb189e1b59d6d6549d59892e29909db8b324e9ef80)]);
        vk.gamma = Pairing.G2Point([uint256(0x07ca41f8b66e7205170b32625fccc98b4615482853bf582eb59dc076a3a2d2ac), uint256(0x0a044532854e08be1de77566f15ada7a79a987ba48101ca2e99e8962cfa59b27)], [uint256(0x2eeb36198cc00d20a1506f3c89e30c6f540486bbfcfca8ef582577dac323d5fd), uint256(0x13a82a78fcec5a4c9af2ef360b4571442c2e61b7b765ddb06fc41694c244e99f)]);
        vk.delta = Pairing.G2Point([uint256(0x2d8e7b75a83c93dd1251251ae0bafcc0f452675d479ace3ebf14560af57bc53c), uint256(0x1adba18c08b8dff86b82dba50ccc9296e898e3393edfeede745ef8ba23517250)], [uint256(0x127d54698f9c58eeb5d93dc2319cf9a9fc45e36451f80a48cc980176a9ab1b92), uint256(0x2f7cd71174f2fa991e5ab9a4c01d5bc35585ee6f051dc5519fc26db9ccc6bbaf)]);
        vk.gamma_abc = new Pairing.G1Point[](14);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x25c63ced76025b5b8ee0c70f2f2d671c055de8795e143adaafc2d792b3a5ae09), uint256(0x1322c80e47d8de650e619871938899f60668a8e656dc7c09b675fbb59eab5e45));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x134502b21a36c0883dcba391590580159ac138cc2d4a3c270cf04e23f8822db7), uint256(0x0441d5ddbead42b5230a7e00f5eaa31c44bee5be51670fe6c84f718fb17711c4));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x08e898ee2fa79f907306e4b45331484d1b91339a0f79b9db620effc0dc623f39), uint256(0x0a87b221f02f6e2ac6ac9c48037a44386a9ca91cef724feb180dd1dc321b37a2));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x02d8a1dbb406280927934f9aa5fa0425e44f189cc1ea8e91161c77a62073b38d), uint256(0x0b4086fcb5c68b077048067723568f93815afbe25b9ab1e47416a420af8724d9));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2d6c368b13154c3a393c74f730ac4b5272f6b8c0ba115da73a7f7dcfe1c45194), uint256(0x224a2ed2338163a12e25a560e6481056703cedbce4f8c4846629549f7cb2992d));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x26ac94a1a8ffa27d5f0e28aa516a49fb60b10b7b2db5c700ab01b750aa9f2964), uint256(0x25079861dbfa6e9aaeabffd10bb7139eccd4a91611773fdb490710eb697bc4d8));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0ce755c0d1e9f0849acfa4e0fdc7f7ea6f130511fa8900de680096b11c54e128), uint256(0x23886b16ff0ba865785924af910fce219836d3c60188ddfc3c814da5a9167255));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x30044f90cb4d0f5b8ce853ba4601d3c660c6edb26ea67c8ce93674299814454d), uint256(0x27c6e5f70dca43162e0ef03094de068cf50e16ec7cdd2f74c2bf58f88718ba63));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0d7ca8ba7e8cb729b5b4953c49dada61a1a6a6c176359bf0fce00cfb93c0c9d2), uint256(0x13166b51e86c7211aefc4b19a37b06f9a643cf3d0e77e1113f4e554ab559a6a9));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0ad8c96a3ceb50fb2241b03ab433f8564e781c2648807e8c13d5a14c52a92619), uint256(0x2b46f45d19f0c79c2d9b54bbf39254de31d9f7170ac7762229c6fbb02cec527e));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1219556d1260706ecad5d47cb2ad29bc739e5969620d1af828f766e0e302619b), uint256(0x19cb1a6c3cea84fbb927e76721ce96da1477eebcf25c8fbff6ca72a22493aa78));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0e3bae34856410cc5f70d6ca2d604b28f9fe0272434d4ba9b43ebb8916953345), uint256(0x10e6e1a041e630150e0c84efa5d2b682c56339a3af8b466f653447d31587b31d));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0e4da0260aa0c6b3e85faa848fb148c2d4ca8a16593bc6f7df0f85c3fb93cdd0), uint256(0x262de6fb5d38b931beddc0907605c751607e53db269513e1200ca3c95a03abaa));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x11e8fadd161722256dbfcb76a05b5adcf9bb89c39ea0a728a3a94f15a3ec2346), uint256(0x103a8f237e8941baea328848ee34703adcb2d2f0440aa8233fb9401bc9dd06bf));
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
