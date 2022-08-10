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
        vk.alpha = Pairing.G1Point(uint256(0x06b9b2f251af368c0a8e30dbf4116c36e0ba943bbcc38f1a3e8207d3da5606be), uint256(0x11c511f878d88759903f3f8c1111952534661dbc49cc5f1dcdf8e1763b3a1d4a));
        vk.beta = Pairing.G2Point([uint256(0x2763bb0b5abeda40b93442d34989f8ba0df4c97ea4c6fd46d1f7869bb3491e85), uint256(0x1ff1128927bcab3c2d54e09beafc3baa95ab0fa4cd37eede124e8a784b8b691d)], [uint256(0x0bc5a8c43bfff6fb48b20ae80db51e23f1f46e3d9086f4bd22af06f22ccb78db), uint256(0x28ce2bca3c19bfd99314d50361f62c64b5363536afb5393ea0642ea82bcf3f25)]);
        vk.gamma = Pairing.G2Point([uint256(0x1554612f5c98e16902b23a42c05b2516d5a213641e8fbe38af7c259899788469), uint256(0x0aec3145e9d17fe181afa9bcf21a5e7e488f17c301faaa3c6c43d0145ea98f21)], [uint256(0x274f0b652b8afbe3423ab2870612337b53df00578be7d048631eba33505346c5), uint256(0x0c8bf058536df141fff4eb0d3627edb96375d7a60374bb50ecd9a88267e78674)]);
        vk.delta = Pairing.G2Point([uint256(0x2fd838f2be41f69a3ea263ceda9d23f2bc5d715d91408dbffda55f6ea77f7089), uint256(0x2d3d887c95826c658927a8648ae9982e1a5d6db7353e3755bd10c53edbd6357d)], [uint256(0x030c974c1068cc147a98ed3f14828e945890f93c0dbc10e5ff3a9fb895377385), uint256(0x0a84e1799b10964b5baef84b4486a0d975435992ea0e2208f44a539d273ced11)]);
        vk.gamma_abc = new Pairing.G1Point[](12);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x02a68d57f03c710a73d0518a17cbc3f6d75fffcf1e06eefb9d900e9f59877640), uint256(0x1e1a8015f39f5ed438608a451f989f45e716448531f66d8a4158f1f78185a76b));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x21572937d6ccdcfa42936a0584ef0f02eb3d4a0744f5cb43aa97d690a29fb190), uint256(0x0e806f5fdc6c56aca877ff810acdf4ccfb9bd95ac5a075ab41d558289e2a7c40));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1c3e349e72837f24da1a12714bb50aaf10f65ed83b49738b964cde0df4f5f001), uint256(0x01d990092d6ae0a3ba4006c874ac1188cb168effe2d226fa11a48305e9945ad1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0da1b11cd96ddd68938f9e6e8ed8e6571474e8a7fee672add7684ed16cbaf6d3), uint256(0x03237735c5afc8132515c5fb00bc979825e4a6498fbb573c16cbb648fec1e038));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0cedb1ed9bead67dabea36a2ab22072003a4f76f786fb2f2af688bca099ba3e4), uint256(0x13ee1611ab2c204fd6c3bd0623cbc6e9b877d0e6154cb30257ae31543868513d));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x01347f9a874faf0f888e7768f68fba863e01a15e84da256e0468a5e685376ec1), uint256(0x17d09ce8f5d34b203fe300b4715bcf1a7be34a2e8cf0daeb683a350a383d7c54));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x048e0b7b04644a4d62398f657c7d23becb87e4e815ac5afd64c327d1eefa57b1), uint256(0x2876ab28033a0ba1912495569b1644efaf0b9dc97c201202541e204ffac4af69));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x09de109dfbabce932598f30ddc8ea3b4bf2a62ed4ae579dab606978c48c1db8f), uint256(0x1483f92ef53396cf317ff7082310d728333b172cca1f5f8435af05986d162a4f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0046a2a89365b29015f1391793650d2b327ccc0cc9fbfebede3d2f9385fbb73d), uint256(0x249db8c64f214e9a8a404c024ce512575af9bc56b3ddd7528eb221e0ace163a0));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2b738ee174203be92e467b015ab232beb3391e00976b0479918df6a8a9f436c6), uint256(0x00d3785c8626dc7e770aae2e7561398b76d32cd0dbf833f452c4a96b61116e6d));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2f3788721fad414da248bd18facb47748d45e05184792ebdf8117ad54dd3f374), uint256(0x12b0f81e39ed6326dc47318606d02d315ebea2a5f39c7b5d818a3359c502ccbe));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1fe8916040046e4b89e80734af19dd34e9dc04b6c32647c8380b8b3798e48675), uint256(0x1bcf58be0b33cda07359bae26b428f06c94ed9949af5453fdea85488a5cd5ca0));
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
