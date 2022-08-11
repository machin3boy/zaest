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
        vk.alpha = Pairing.G1Point(uint256(0x2fffee4ab3e857a9623aacdb776df75116dd101623550ef08ec34d15db68bd12), uint256(0x2bd9bd3f034f13d40e77edb0b3d7339050f6409a599512b1d8c4f7ddece9af19));
        vk.beta = Pairing.G2Point([uint256(0x1dcab838e6f105409b44a8fef371aa8016fa039b7fa3c10e8b10671aa73aa6aa), uint256(0x0ee29ee8c02f1738eb76564116cfd7dd99ffce2d4531dfb24f24159bc09aac30)], [uint256(0x1c6ab1646a87300fd25ca5231243388ec3fcdf5a351d91fa5a54b0a4e3899186), uint256(0x25490b07ea6c25f884be48dcf3751b595416b20d6c0299c78fdf80b6799a723b)]);
        vk.gamma = Pairing.G2Point([uint256(0x1c528e8caad5eac17fef73adf1807d93bdd5f6fff87f9b5bb7085ab6586321b6), uint256(0x210bf67ff2d213a8edfe88be5861ec00ed13ae65146c4cfe9bc3311d349042ca)], [uint256(0x241661ab247b2185ea21847312de7edbbdec1466f99bf9960b1eceed481d44a6), uint256(0x17ef0f3f0c2fe7ae0ac9db214911789132440e429d4affdb95002dadb75f39df)]);
        vk.delta = Pairing.G2Point([uint256(0x0982fa0b66e82727df5c6ee04b7a549ee3deb444c545fbed0940e98d7c18697a), uint256(0x1367471af6a599bf6e08b09625cfce47ac703cecd1a065181a61eea3f96fe397)], [uint256(0x01935242e4ec99e5efe354e616749df95ac4d7c4d6a899d222f77e2bf907f3f1), uint256(0x073bfe9456f353fe6245c194b54425df49dc2e4ede7b98a207d59142abc8cbfd)]);
        vk.gamma_abc = new Pairing.G1Point[](20);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2b5b3c7df8aec682b682a23dad4852c5fd80d62867dd71f649c8c9b8f95d084d), uint256(0x2822d9646ec3cd26ecd91c07192b9a537693ed11257d86fcf4c47df0f810adda));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1a37d7e9d40a220f714cdf690f1515eec6108e444711b29d3e1629021bda72ec), uint256(0x24a6be5dd9578dd76d94533beae6462b4ad8f594d2145f8a6920be79e64a5a32));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x238f2f00ea7b63e79701528582c2ea0390eb3478e627d86d8bc1dcd6cef99334), uint256(0x094980d16b19e22b8c8f7b973f690981e251d486cd895a359ac3cbb585268d00));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x14b8f21bdaf5ee5cfb8fbffc0e48fe58cbfcabddc3b81b96410ad4dfe46a4379), uint256(0x0ebd2c9395eba7651a461bafc77a433d5c196cad0bc21471b84687964a96f765));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x28f5a6dd0edc8bfe81338fd60b9cfe285a9bc8dbf51359e55fe699131eea016a), uint256(0x2411b6dfcda7ed35bb4b8b9947515d0d60544b7c95a57be9a273cc81d3837f97));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x002f6b9d59bd0744eea06475ef6f83c914d5fb7017f3ac7410ac9d535e3a3a19), uint256(0x11873aaef17328105ffdfc3e1251bf7c5bc7dd5a5f4e450606d33c89771a88da));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1f859e67bbfb51a3e0043761b1e7aee856138d52ccd5bf6d9771d3d6360d054b), uint256(0x2720cb7448e35ed54eeba1e0f82d4cf6de244283a663f47a83337d884b888c92));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1060399818633f38d6093d6e32b7d527048737f6f61fbc8048509cc457a30590), uint256(0x06e3128d2bf79f5991eba131ebb5011f8ed4c243a3db54661700c71a424f3db6));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x21a9b587c41d998bbea1ffeb39e46819131fc419d9884a24c28af126ddd853d3), uint256(0x1db5f8162a63afa4415fd8a0b9b0caabce1e3e5976928e676b9c33c526ca28df));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2a354142e8332b9e0377a66fac87b0cfade22b3261ca793de6fa35e48bf11783), uint256(0x0f8139a4359643425e7d76f1b520ef74dd8cc0850356a6e1efcafd0259bacc48));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2a0884c7de774d4a3a47c7ffa05d9d5fa02a1d414d515dcff43154edfce5a7c3), uint256(0x0ec7e37f0370f866fa8a465cf065344527078028f3837b808b21df79838f557d));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x05e95325e3afadbb10752ec8e268bad1d382fe82a0125020c63fe9af4b56ab86), uint256(0x0461ab115f6a38dd32e6d4e89dc109fe367ca086c3cddfeff80510c6b106edec));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x04df3430410ba66eca897e75bac7cc9152c6f8286172e3d01d7a5bc88dcd42fe), uint256(0x0ac99bb81f4644c7ac7df90f1208923cd640be9d1c6accd408f2e33d61e8ac58));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x2fbf69d55388de767e45fb3c1b56a03221bfae550a7c693c8733614aabafeb3d), uint256(0x1b3fa83c3b229acdbc2bf91fd56c5dfd53d392d11f5eece12ca404cb92322a12));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1b47116bace8fc54f1fe693cc053565a5a89e189356330fb3ce20c9d43d58187), uint256(0x2745052662f570f26c21cabb1e865a73fb6dcb12f8d45a56012f2392a7620236));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x15ca55e8e8c915a9209215f773012b4a5597ce932e5237007ee8e4a432be3693), uint256(0x2dbd5581395beedfeb0f5881d86a889c35a393ff51aba409270607976e8d2066));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0dd35979d272a3d9ab5bdbf3f6cdf80c67bcf335dead433f9f0ef8ff8cd770b7), uint256(0x2c48ae107d81d0fa305fdb84a61a275177d6f7dfb50941a5fc37cb5722437b68));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x1672440c5fe86d62e67a8b3b93773957b56d11064f484fe95b781875590894e5), uint256(0x1125be58b163010002c68b1fab670e2b6e846b09f1664c3e22658a000129eed0));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x085e76aae86d001ca111f039e7d7e45bb6cf4c5b8211d99be3abf8d13eb7c204), uint256(0x114835608d38b2abf9e35d1949914b80cea47e6db05b8eed8d755c58a2e66011));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x0f42a595e7bc433de28a9c1e43d8a9ffcc315df3a490bd57060a33d8575b044b), uint256(0x119c5a73262ee6e7931e1660ef1c7a82892c7cca2c16df930ca5119d9c2a9000));
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
            Proof memory proof, uint[19] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](19);
        
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
