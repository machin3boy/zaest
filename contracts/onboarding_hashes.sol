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
        vk.alpha = Pairing.G1Point(uint256(0x2e18fc767caf1219eff80cc604f4c10ff78b7e2a615090b4604de8b3afc9963c), uint256(0x07a5c898c503b24ed6bf015458e4c675b0709223608519a25e653452edc1503d));
        vk.beta = Pairing.G2Point([uint256(0x0af2e9384cbb5a01cf8fce5e8c0bb0e9ba31793aa85a9016322c8d8176bedbba), uint256(0x04146712992864099dee348e9c17fe0030481aad4470e8282de15c90c81c9ac1)], [uint256(0x17c3a229f28f1f8e0c879615fc980f19e8d5a357842c8a4a6a3c12377d162398), uint256(0x1a2e7712ba439cfe5ce3f80e99abd0674c5eef10beb1f8f03148fc4b68c6092a)]);
        vk.gamma = Pairing.G2Point([uint256(0x0f3c94f93b5d13cc29cf6290105dddb32aeba4711c3b09492b8d7e5e9cef260e), uint256(0x03c0ce384117aaa7ede6958c33a08f0cbfbe3be25d845e7e61b448a2745eb7fd)], [uint256(0x2540c68b8803dc487800dea66d35eebae6d25e91be3e8e38ad1f99c85a40bb9a), uint256(0x13dc1b334f0cff4ad79162964a24006c923fdec58ce411e2683b95a3d4566d49)]);
        vk.delta = Pairing.G2Point([uint256(0x22c8c48c5d17ce673a011e1f81d3a05e63a974251d3c46d1ee1de9f443ae8c2c), uint256(0x03d651e89de03c411e1d79e6fbf2fdd9bac2409f6575100d650b3ae185d06c12)], [uint256(0x06dd3a3d704e903052ba7dd4fe7adff9ca0cfb30e645afabde8e785925d7b6b9), uint256(0x1c8e0c71c5831cb1e9287b7ba77e838167e956cfd1764e9df0f9f7f7b4ae1d24)]);
        vk.gamma_abc = new Pairing.G1Point[](14);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2924e626aa9e23cd486668d5bfd2cb2d04c0be481f3ef8bed3effe746d66f998), uint256(0x0e2b2fa21872a2e3cfc09560ffebfc35d9ee2752c3bee885a133875848b32f4c));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2221e7f600cea95b1c8b821996ed9cbd2c2306ded1cb5f9c1dae6871affd0453), uint256(0x1cd0774426a4a98ef77e7fa743b26065dfec83b0b0022ddca79843b7d6c90b77));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x1e8c8bc9b0785255206afc740cf875ffa245cb4ac32570a0e7424d9fd91de800), uint256(0x1dbbac77965da2859da8eba90756330e241ff23d54b26d26007c88f715926aaa));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x21de716c269ec24bedc0fb5137edc4bd900a52a4da0a9fccbe15a20789457867), uint256(0x1a209e343d51fff8cceafbacc7ba098d64eee1ae8336084a7620bb3a2391bb23));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0ec8af23899bc1e3676849a64cb65594bbc387a577de2a50b3c96b91dc0e5d2b), uint256(0x0440c6912a8d924aaba6735dea885918084ef878528b47ffd3ad4cdaf2426b49));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x13ecb58a4188ad9de2b98a3a8e9da43dbf28041efd2c1b141fd1179ba809a455), uint256(0x09f562eb8022e7263edac3f0e8859b7876882e2cfab6bd100a95090b1cdab24f));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x006f7e83063b0515189482682c6082269c8b44ca0fb161b1002f0dd8f235e2ae), uint256(0x0112dd8abd52e9f17230daa40ea25f93276b7f0994d0dff13a50919298a7bb7a));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1a24ecebe083ff4364be79053f11a9203cf74d2c3afdd209afe2b5dae93bfca6), uint256(0x104fca6cdd0518ebe66e8c5e5cf024407be37d212dc35439611b18a1e442cbd3));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x258660953ff03d8767da2895926b93f4eeb8ef05acd33cbec10df3ac042bda0d), uint256(0x044b4149d5647021825ad2e307357c852e2a8c9b346b9125c2f9094cd65d2b16));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1ee211f0e5d1cbca2c7227ab1e12aeca1f6b725df4bc99b2b0494ce31127c7b5), uint256(0x2cb3c182553d6819ed0fed20f1811875498ca8672bb3b96d16df045f2bfa2aec));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x02cc56633dce1b55c9f98de3be230ff2102db77e95bdc428bfa5a106807d11f1), uint256(0x0b497843841efe4d6e8e9ba3480abf869b0386402a367cc775547767a6eb84c4));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0c41d83f446e35a1caa0d5f8308075d1269b8b13901a5e2f4bbf2fe6547b31c1), uint256(0x004981b0bd1a341f6d4b1318a1824bab949e345484d1ac19606be3c83a6ce1d0));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x203de5f8618515901d00bec0307bc9b9a6a7be6b9e193a57c2acd6755a1ac629), uint256(0x06108dc7dfdef9337744c15ca2a9ce79fff1ae36774e9208dabfdc3bb365df40));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x0066dd7fa1725b458bcbe1d520ddaa4a43023080e9dafd6fe5c2c5da51643eab), uint256(0x10a8ec9a031fc0859e4aa8c62af7ad796d72cbe080f789288835af5d8cae8437));
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
