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
        vk.alpha = Pairing.G1Point(uint256(0x02a4724abae705ef25605223d9249a1f3a7d7204419b9e71278c7ffe602edfea), uint256(0x0d04907a92a801e44525e5f0a24a950a179429d63488eece02e3e0ad96a53937));
        vk.beta = Pairing.G2Point([uint256(0x29ba2d01afe86137237012e5d4d8fb40144af7e76e078b48e2b1d5c015d8e9ee), uint256(0x2a668ab42161d13f8f7a54857bc0a445f8b0e78fa2b02c5e483fb2185b941a6f)], [uint256(0x2959d5d77d102b62d8226556b3890749be232ee92ec94822006b285990bc7b72), uint256(0x29080e1704c7ee71051b7252720c9d27f7c6648c8ca5c3716f1b415084c0721a)]);
        vk.gamma = Pairing.G2Point([uint256(0x0fbccf975940c91a0b16b99ec529eaaac4a0d000ab0c17556a21597c1a3b88e2), uint256(0x12ee2b8bf9ff5090f0e0e99c4c1afef61faab55badb3a70053d34b18b74d1549)], [uint256(0x2b3eb3e42c6048b65723c3d95b1d6c3927327a7824a72c1b57bb25871815f48e), uint256(0x25d3e93c735f3b0820315555f3dfefd4d947524ba40bc5290b42c405b704c599)]);
        vk.delta = Pairing.G2Point([uint256(0x2491d9c192098dc16b1950f449011851a3a7633cb831e18f6c11bce097140ddc), uint256(0x22df04500b46ab1ade694bde828fef92a44daa5170c283134ae3de9486829f25)], [uint256(0x2a4628dd76ebbae0da93cfdde48a294aa7b0ca4048453ededb2f3e60765a2a5c), uint256(0x30185959c77049f157c8977000abfd51c71dd33229d67a0621b06969f87ea5fb)]);
        vk.gamma_abc = new Pairing.G1Point[](22);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x160f824d852d95ca068132f8cf4e6782049fa87796d6024346c6b52e8f912612), uint256(0x2e9fdd0646d2bf0946646a51955fd29474a993e7e8667ebd97529819696cf9ee));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0bbd7dd034cea8ed43aad7f99d93e731a2293987224fd36ab2da664c93ac2167), uint256(0x1c6d50bb11660ad9f71e61e05bd8ab5ac2e48b404cc6abeccc0be6bcad193202));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2fb09d3571255659c158458c3e1bdbbbf09982ee3bbd71219959cdbb681dcd3c), uint256(0x140699fff14902761f913f02b7f8dab2901a08beb0b9bdf4da74f781912ef3d1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1a523f1c2723597600828857e25c07003e2ca254ab01c41caa8acb22c7d60293), uint256(0x1592a9f921e1ffe6f35d7b1e648b4abb9576d43fa9f71371bafe84b4de0c4e40));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x190d3e26073805ca91b5d1b9d3032f3202b4a5401c32b6bb9848415f8c9692f7), uint256(0x04efe59a43226d1c505b2671589fba9ac5ecc76c2de67cf08a3c04219dc2a6b9));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1dff31883140c8197f4a244c081eb0652eb29e7e3ff39deee7b3b7182b78f297), uint256(0x24ce6187309ed54595fb8d119b76e06de1b1d0e9fbee410843978b9ed7a357d4));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1eaee9f735e9d8df998462d806687c751ffe0dcb0383ad29cc40a781b865b5f7), uint256(0x2fc43d0bffe9d9b9542edd09b43a1c0f7242e9b0d198e081241259b7fa60d599));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1b05e5504ee4d99558c42bf5c2f2c94bcfdf0cc5f5bffd3248c0e469d2d0d25e), uint256(0x207c008807249b608c25f55c408983e1c00a560338ca3698b54e81139d62b29f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x20eaa2c7b74e87a9d5755c522a1ca85b39803f2341a5d1344dca1c47810f150a), uint256(0x1b5283c36b6b10d6cfa2b0aabe5e0495790da8dad42ba5ab5110f9a96c1097d9));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x042d6de65e09a7c4eb016d6f39e650d3e6f08eb576921a66ee248cf84054b4ec), uint256(0x15ba4794e4271a2e1965b38bc46df50d8687a336fd94ca3fa8969ff940506fb2));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0110b91a08320517897be7013cd04dfe9dbd44b6191fbc91dc9d4124bfd11f0a), uint256(0x00ad8446e90a0e0554c7e3a1b4894066aa5b47b4c25b76e2be217525ec8242e6));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x222bddf25248cc8d34d8a0363d0d0f68bdc8fc69555eadc9e736efb063c66971), uint256(0x0de2b3c0668ff8735e1e01e64ea46b68426a19eb81b626f532ee94c8484b3c99));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x044463eb5fa6609e9a43645bd2567ad84f93af048091b073fcb64e2f4161011f), uint256(0x27d7a047a1cd9a515e9b67ec1632551a0744246ee57d6ad5243aedc6c8abb1f3));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x19ab347752b0b14d1f40a742b62a466a5ba57353e9bd9b9e5adfec71f20a8827), uint256(0x16c520abb1d204160ae21ef879c21a7e1e809f2e7d0e4c5eda2688c11ac4ddda));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x010591daae433f3cdd10daab06a363055591d1971d3f5f24f709639ee9ae8de9), uint256(0x231e17a2a6f30c880f0dc9429cb7d360371c3bc4820f45511b4e7a8c2dfd2a9a));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x269eac840a4f12cb6e258555718ba0e8b713a6421fb1c0ac2a0e350835f75119), uint256(0x09bd72736dff381efccd52d83ad43e593309914aee9dcf34d73ca042627b8f75));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x189d6d50bf4c972e9fc15dc3ae56a3dadd3cc73885837b5cb35c21c588a8d16b), uint256(0x19d7f9299b2de25ed3239232aa24764cbad9a5f0eb0501593f2df890b18c7b11));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x26b5d8a3217e972de86f48d55a1bfcc413f230fe7bcb93a5985578bd2eee39c7), uint256(0x053cb83e8c81bef1b01b5f95ee6bcee9468cdd6bebb8c62224c14d8e052c6f4c));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x056ac3a8c40fb453507170174010ee735208e52bc96a5b9d722ff97084ae4eb1), uint256(0x0c02118956a7880b8e9e0a0c3775bcc515aad87415001685d38ef39ceb69e159));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1a9444a092b48a5dc921aa5589d240308c09b7b8cd0bb564b242a40db034f0ac), uint256(0x04dc6bbda728b805cb0ee6749427c08b50069b03a9acdd865b5dbbc14eaae12c));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x0367efd5fc44c587a8b65d49b059ec0b5ec83fa8c6541848d22625e3ed48a277), uint256(0x2a419ef6afc869b316a605d37fd5a951c620d11002e90085ccb808ab3093d339));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x07de97fcb56c1d90d869e1ca50ae6f1e5a51201dc4421399fca8ff65f94eb788), uint256(0x1769db2b6e757cedb55d47f0ec00d5be51786919dc025868b071d37c9278426e));
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
            Proof memory proof, uint[21] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](21);
        
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
