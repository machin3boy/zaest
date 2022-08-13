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
        vk.alpha = Pairing.G1Point(uint256(0x166ec01139dbd17ad5f761883e9d0a4a9a57e0b498714236a720e33ff9c55166), uint256(0x1a8d30883bf1bd4eb5d96e33a21d467be8e126373993dd2bf841dfccf9427947));
        vk.beta = Pairing.G2Point([uint256(0x0d80cb3f265703e21777e878e24a0a51d0bd3db33c90d67e03001442b87cf9be), uint256(0x16f6ecdfa32a6cc844a0cfc2ec9cf569476e486a609b0f5663d54df9fe694d3f)], [uint256(0x01934c47611f3f29acda9c06df8d3d57710b305a3e05e62078113d4112bb018b), uint256(0x26251e33369f6e07741e35ebcc0aec7f4c044821761cab7f5d5f167ae2dcef99)]);
        vk.gamma = Pairing.G2Point([uint256(0x288eea2b70c3736a4494edf0913651e79958d85d1fc78cc6317f17c6c61fe947), uint256(0x1a859afe6761e0191229db67c25d2027e408890430a8a1bb886f14d4c07b69ef)], [uint256(0x157065c5a4721e956b9a84f70c1826ead58212c98fd11d6fadd2c36b15177721), uint256(0x22437cbbab11adcd95d27cdd107752021bd7542804a2ae67c2bba24a8bbec78b)]);
        vk.delta = Pairing.G2Point([uint256(0x2d8e18b9616300d1371d4436f0fc71addf6991292dcce806a6dad28738a57be6), uint256(0x07c8dfb27cb863536682b9f9898913a3ff7601ab38ca6348e9ad419397561672)], [uint256(0x2dddd92379f3a5119a21c1b8a3ec7b6e3b8bda5b88f84e03f497deb97fac4c0a), uint256(0x2eda1b2520e2acfa9d23fa7ed7b5571b23a40df7e67d2ce9c3f5937c8b6140d2)]);
        vk.gamma_abc = new Pairing.G1Point[](18);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1c11e9241248f7d920dd87fb81cdcebf586f7c4e48bb8b32471742aa765297a1), uint256(0x01a2bde9f1592e8b685ae3ff0b7ff945759778e932d29ce8ea1f140d39ef59cf));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x15ce0d8d03f1bab9b47b6339bc68ac4beb8e1f02ac01e704622d90db985b8ab1), uint256(0x0b5863ff915408063b3e30fb8bab19eb59dadc311c4dbf94daf15c6ee6bf516b));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x299fdd0380d23bfc7f773978e6299e472f1fa30487c72b951c867d33338f613d), uint256(0x280d1796c41ed8772b9a72c8fc6e122d5e511db92e6fef9ca6ebd70ca44fc249));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x04cdfc320adfc2cee25e16b92be35bcb0a4311e05d3caefc3def5f699c32a2f7), uint256(0x28a72ebd5a215f24f42786320c5594c32cd2d40e9a191c41a6068d55bcd27f6c));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2bbcfc11bd308716929fc4ca9205e079ca49e1fa9c5f8b4707b0c165e0ce1420), uint256(0x142a5b466fb21d7e2db8a9b6f52ca9ba7ad22ab4721e2cd33eba99cbf1671760));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x050347d3f6cba98c9953e06630bbe22df529b8683cfae79e6de407cc14a36d43), uint256(0x0758920dbdcc6cf8b049a9bc21f1f5dac3eca0df3f184f56dbbbb2aabba8546f));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0a076b1060256ba9e793a7e04611456ddbcb6012f156e4669ad723ffdc97cdc8), uint256(0x11aa076fe03223237ed23d6fd8980e7927e0bb6128dd1a6027a192542fb30278));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x04f299726218fb5012c728f18d75b5392ebbc4ed0cfaac22d311080876d2b15d), uint256(0x0e8283978fce6fd3aec69e2f6fac4c16da3b559ed5f4163afd312a4e3736b4c1));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x26d11898e8c854f621f5455ca7ea5db9812dfdb0230c4e53470da6f999d7f5eb), uint256(0x1dba35c5a9ce18380c5ca6fd0539ca2823c36fc75b32838c19a5adba3cce8f7c));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x218cf070ee7d2a1fd3633f91274a0f614db5445a6a769e64ee82f0c36eb48458), uint256(0x19026ad7cd70512122f4a5da1e06cba1907df0724261261e5c6d8d03e5d37494));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x01eff9e1d43debee313e52badc8ae9fd4e68bf51be3ad92e6d228d7cf7bb6c49), uint256(0x291b11bb5cc4d74b63942c43b108e837226ad0da755d57163757018b2dfbc9cb));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2ec3f17dc86c086eab7646e8d3b00fa31d581286fb9a2a8236a65c34397a5a10), uint256(0x215446b8996280fb7cab9dbd461603170f4603cbba39a664ce95ab6266df1904));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x071365cbc1a8e4f38270187eb6b89180ef0c003475a1ba9bd5727280433ca9d1), uint256(0x286881c5f11c64bfbad360fb812f7536949aeafba7ee47d2ce73ac513b40d731));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x0e058fad6f6eada46549fcb04313c7b246b5e6a53cf6ffceaa6cffeea0e2e2fa), uint256(0x1aba6b279cb802512fbf77df7a2e4a489607892e124eaa8daf513818e7f4f1ca));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x105f35e4ef376d65d337c17d5a740c0eca243f707fc95a689969ede7305dd328), uint256(0x126d902d5d62d14cb579f3579b47b94da9f465a1546aaceecfeaf73e135928f5));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x218177ce4b60db0e6cb50e2256b173d4a79b701b01354915d01cf96b17ca2833), uint256(0x1e13e0ba27173871fb24a3902d4cad9d260fc81dba28c37e300cc6f7aa2e2b65));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x1a82e27292de3c045a2ecd01afc8098e5c7dabf6209c9f312d3e3091ea693121), uint256(0x067d1d76a0687a034295f91edc02cf57e1294d7ba46232076c2a1a67ad7733b0));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x30522e0a007f299d0ecc9beb1c24ff78d91ff56dabb3aadc99231f7217076695), uint256(0x1082484002c291be388c0850a4be69d08492947cacc640c31e2375313a1cfab4));
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
            Proof memory proof, uint[17] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](17);
        
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
