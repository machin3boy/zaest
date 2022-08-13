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
        vk.alpha = Pairing.G1Point(uint256(0x1c3236cee16aa55cd62e94c0c49ce6bb9f148eb1bc054df877ba3fed8bc7366b), uint256(0x25982016d0483036384c206ef31b7dbb8bdd037608a7605c169a230f9accdee7));
        vk.beta = Pairing.G2Point([uint256(0x054ff5cbc3d969bb91546c814344de0a5ac7b6a539f9067c67e025e78a2f644f), uint256(0x11db04285df78eeeb6f3803a9945232da1505bf3bddadd7450b0c281f22d4203)], [uint256(0x2a1eb0378ad4b164052f14a0dea1b92b5132d5c68e0e28186826e355a07af483), uint256(0x265f6f539cc8fd21ac94e03527db0fc186b92038b23b32552c3153dc27ad1ae6)]);
        vk.gamma = Pairing.G2Point([uint256(0x15c81bf13c4939d7605da699bd20352c9a99758417fd4164ac7109d8df451732), uint256(0x2a51a46973305206279284282cd3a38153ac1f620d3ad7120b4ac1b6e1f1a849)], [uint256(0x2507a2d3670b85502c02a932cdc195984557c6dde82cb85e31aa55735d446b67), uint256(0x2c2568bea2a970624f69655d01caacdfe1b5cdfafb4ddfe4bdf9c6ff1b011969)]);
        vk.delta = Pairing.G2Point([uint256(0x0de78a1226f885f1e06a0face73b1fb22861f1a7110a84591a9dbb2e634f7b27), uint256(0x2e84bee91e7a78b77d367e17e426483ab3508548f922ac37f44aad7842fae01a)], [uint256(0x080d8852740943d59a72284b1182278192c0dce861f9c86e807bde8a8cee5ea0), uint256(0x0fd3ea2121a65d941b057214bc2c80e442a51109b71236ae4dedc4e7013ae4b5)]);
        vk.gamma_abc = new Pairing.G1Point[](17);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x13523f897a1d2bd788d8d816ffb6ba9b8a88298f992eb4c30cc1444fc14f7e13), uint256(0x08f2b7f467e6ad43f6aac5bfde90bebc03011395be604cc57fc9c78cae5f9ce0));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1c72c41aa5ec1e238342b51d47eb9f5dc2fa1c4390265faab1b41f48819baaca), uint256(0x0323451b4846cc851b45985da0506fd9dea3801d376ae339d6028d639f674373));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x14dc31c2cb059dd5bc476f6153bab4c1bd27695f3af8ac3456994f436f111901), uint256(0x12cf04bfd33292f4a604e65f4dbad268b5bb738a647801f2a9f54a6bd7bdbdea));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x10052fa9a9daed456270bd81821892f40d7de2e599f72de4b73fca691cb1609b), uint256(0x23af94ce5b57a19d233b35141b9a918c65657be6115263f6328a3abe5c03a05c));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2d8f11a5573159e598d0db6ee0ff8b89534f89edb045e7aefd0c373bf111e8d2), uint256(0x0d8c7caba88eb6a5a34e999c31bd36fb5f996098c611823c7f6a75ea017ba686));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x246169c56750a6bccee051948c34bbfd90ce82565701982f4fa9a59f7c46a862), uint256(0x0e1d3ae9796febf14cc9623645faab83aa3f0ebbbaaff1723d52457ce7fdb42b));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x041928bdbca51c9ef354ac0b02ca59ef7b79a9e4fce01e42ab08ced4f5ee407a), uint256(0x2dd535f7280710a41fb967f3e9ba293a3efed230cb52dbcd1aa85ad4e98fcc9c));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x29d13252ab61a749def6cf61e3b6481d0a5df2397dbe7ec7e323a2fb01e6af65), uint256(0x145a24f91226efd4a795e424cca717df6f8812ac8f12304407b6d70002fb1f7e));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0fc8d812bf31b68df13d468339104bb19a0d9f178bcbf2fca8c6512142c1f7fe), uint256(0x19c0a1424785c12348c515da4d7e16dc3c0670b7b6078788d047b2d6df1c3d02));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0430589130e232103d20fe836e527757cfbfeb3c8148f02480c4a0343e60ca2c), uint256(0x256cad164167c47ad33a09f4a2825fa80ec0bcea40edb0f16903869c2aaa3a41));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1ecae324def83113a2fda5df2dc40b0ad721bdc5207998f518c389707b2f196e), uint256(0x23bf271b4876bcfa179ac5add60fc18d28eca896b1181e57ac98fe7e74177e75));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0529037c37bed4dd2cf4d2e2313d555a1e3e01324eae7a4fee0e623ee10d8fe0), uint256(0x18e50dca872e672c409f615d6f6cec33efc9c69b03c948a7cad06dcd7b771f9b));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x1decf9b4547adb27cfa83df68e3c3586c478eb996864ef41f6d7e3f947b33327), uint256(0x29c3c11398fd07f6e4501def889e972f000ad74438959681ffe7b73418b5ad77));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2c7c46fca868496e4875ce8ada8decc99d74c93cbc5bc8da15cec5c32099f201), uint256(0x17424c8196d403b3493c4093c62a52fc8b21ee315b5f2b14c168bf2003d7d269));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x188dedf89e91072a22966ec7ad3b148fe4f01bb48c15a87475beb6ce4b759497), uint256(0x0bd97ea4ddb3e78b7a13eb59645c0393f5822037879bc7c16ffd3e20cdfef673));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x1230c41a7246a3cc01592f1c4564e8c6c0a200e6deac847b68c0c25fd3654626), uint256(0x0255c7cae5d56a5767104ca97b10e944270ba5e0bfad7fcbd0c55f003900c2eb));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0ae27ebab19cc57ccc26c6016295aedd8b806df21b6cbd9be9cea78a2f54cbf2), uint256(0x2281db5be573a776195053d4fa0fc7de65421e2633f5f8fffa548ffa685c8938));
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
