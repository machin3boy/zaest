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
        vk.alpha = Pairing.G1Point(uint256(0x0ce6e5c8933f47c1d853fa64f29d27b8497008876db99a0d477c5797929f0b27), uint256(0x16f326687a928418515c8d417e64c1c8c6017e2189a896c2af6d6cf7c050bbe7));
        vk.beta = Pairing.G2Point([uint256(0x2d90de40edace8c345aa2eff3e8d656e0e5e424484497f69baf2d3f16e2b58cb), uint256(0x2a06e3951b95b8e6da5fe8eb023b7fdd4a8b7334b2d071e292b20a78f0460a8f)], [uint256(0x05649c42635ab6f634a8e78fa4d7da8fd9765123211c81afcfe681324e657014), uint256(0x112dada281c664a232b3c145e90bac8604592b8d652822540717ad6635d091a8)]);
        vk.gamma = Pairing.G2Point([uint256(0x1b8b0eb93bfb65e2dfc2fc746861ce86aa5e1068cd234bfa089999ecb2f86264), uint256(0x0f537db7f63abcf9b10846e1d5d7de0a2f3cb81680a3d1e71a90137ac4e27be0)], [uint256(0x19efb824726671e03c26169fb3994689a0d86d4756929f5f32ce72a415899349), uint256(0x0738740c3a999bb3910032b2106fa97a5c5bfc35d80a2332672b417dbe721dea)]);
        vk.delta = Pairing.G2Point([uint256(0x043e26b6df3af4686e024863e33abaf57cd176f65cfd4c192898878b2db9ff3b), uint256(0x122c8ee651ece1e866c7688981c0a7bf89c00ff32b30d9dce9a7621324831c03)], [uint256(0x288b9f25c581129dabad0f4da0569a9c59606afd1f379cdf94f937528ca1c142), uint256(0x05020165eaa7c713d0008641c88dc5e74bcbdab319d0988c1b84ed55ef7dfa43)]);
        vk.gamma_abc = new Pairing.G1Point[](12);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0eac1d9a09a8354cf761e2005dde6c82808c85a3ad56e2efef906b1e3664c804), uint256(0x07b3c8ab039997786d615db6e0910bcb4517060db590a70eb2996f23e84a8d38));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x110c3ee75bd0ac9e9738696f4f70ecca3021c199dc3ded97294a958f16f497f2), uint256(0x2f9d8a81f444f33fcb39156b2d4d659c2ffd71076593035fa348b6c172a107d9));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x020a7e86cf50666d1c3d0d2298adc569b862a73ab21ce947d611e92469a1d0be), uint256(0x04bbe1715cfbfb80225abf563485dc07b4de73ca7f2e2a1edff15058d8b3cfac));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1f7a21433fe4ae6201a36ebc37d730647af6f2db42afa009f5a48c31f1a08add), uint256(0x0c06717fd57c27af3eb0d7155922257e81dd6721eb46572b606af6f38be52616));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x22e2b1e9e607ad9b8ec5c7c007104a64191c767e20e033242d1aeb031b31391f), uint256(0x02ccc55195f78e88c6aae43c033ec60f18275d24a326711b1017a3e028bfe045));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x2fe5dc9b290c14726429938e14aa9e304f673fa05c5df07b316f281e50ebe0af), uint256(0x2800ffbf22ed63826dbf43d5da860641d5427a1423e40c83812cb3cc4936cfcb));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x15559c201b4428f28308ba016f366a2b1007004bf42a95a9b65f2b6edf369ce6), uint256(0x0c47b1afd8e658b108c92cf27b2ad223c65bff0895d705bc7aa955341156a3ab));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x054b83deed91f7b57f17c7ef0d906567f53f0aabd8c490b59120da69f8e65198), uint256(0x242e0b1d4c18e2a271ccdf45f03bcadb2d6fe0cde6041918368e52de6aec97c2));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x115e419800deb2a52e0fc11d672e50c26ce6e7c9c2f8cba1bf24bf3c544a0c8e), uint256(0x2f7eaeb38ed0848c5dfebc2320a2c8fe12d271ccb9477626cfa927957314563d));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1700b7e0f93ac48bd70dd5c116dda16afb5303f2626de09f352587d8f13524a6), uint256(0x17c4e878be9a9d20b8e207cc62f090721ef4fdabe8ea1ad47101e246db767dbd));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x22374812da91eec2e0fa6e45fbb573a5507f466730eec45520c4ab881b17f37f), uint256(0x13f0ca65314b125c185f5e693704e12633369bb503474f02cac17264403d81d5));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x248e98d5f4cff3e00d3fbc90b4dcb16e6b941e1bc875cb4da602381f8ca08556), uint256(0x232f4aaa4831e8c271b1a071dc719f93a95abb1af8ca6e8dd8b1267f7e0007dc));
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
