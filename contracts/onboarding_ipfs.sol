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
        vk.alpha = Pairing.G1Point(uint256(0x2dbe2cafb2c2656bbd100940052bc43f7a93272fa9489e3bf9ef361c4f017a38), uint256(0x0903a5a63a3dd80df4002df4d04a8a300e28c9c9c1c19eab699baedf38889966));
        vk.beta = Pairing.G2Point([uint256(0x110158cdfd7df0807c2a23f39dde0c164ee5b92bbc64e2b391241cfafabf7205), uint256(0x22d744e6be3e55ae75ff76c4dc27e6bacc3d3c2ac8076b6e815606da515a2e50)], [uint256(0x1fc920cf83b17f97efe78152b7747d78af99b589a943ae91fa3677ce142f50c3), uint256(0x0f67f3f8d7156513fdd92ce71377929a081415331e0f9b00135cd91ca7b9a0fa)]);
        vk.gamma = Pairing.G2Point([uint256(0x1f69bd9cb99e6cd6a937598f017ca3b44c1a5c1fb7cd2d03007572344ed5a358), uint256(0x2e85f8f1e127734890c79ab4871c6a939490b1ee7794e5d04c53ac00450139fc)], [uint256(0x2188a62ded8dc3a31351010b7663122e4875d0904990c3236a594c91361bb590), uint256(0x29248d97c17c61433afc26b5102ab87adf088d48f8a72235ab9d53a012a44860)]);
        vk.delta = Pairing.G2Point([uint256(0x1f10c559b6121ab9cf3a1dc96ccf022be4ea67540b5554071d21a5bd1c66dd50), uint256(0x0ac8d31a79d710574e9a16d5f8fc2fb3dcacaa0b61fcaec16185acd6ee27aebe)], [uint256(0x0238939b86a7878ae7163d3a9077a9342559300f27b69c4abea6a2dd07e57917), uint256(0x1272562cc178b7c88a54e64ec5fd0b76a0e8942fc768a086593c98415c9186c3)]);
        vk.gamma_abc = new Pairing.G1Point[](14);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x099d03d3a9dcd0c7ed000114e10b908bc78233dee24a70054799fb1ff7862999), uint256(0x27b74c8b88b270d3b7614a395f519236aa44aff5d2675aaa077095db777ee22a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x238a380c846112102bc0a98d4c1ecf13cf7a89d3fa368a19c2c4820aba12af67), uint256(0x238765637a7b60c07a171352e69f41bfee653f438c70857461236701ed746936));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x150f469bc8bc8a20d0b2d9c8f4e4f4c1013fb031ab1d46115c8bd0f2bfd62694), uint256(0x154c6fd0cee75ba4d78b53185884999f5a71ea6f63777a841a5361fac19eabf5));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1db98f91d935b3969699e3ece0dfdcbf6f0c95831013dcd2d103c892c5437167), uint256(0x107a5f449799bde8a42f5f0a227b84c3d62d2a284c40094b29bb8560f8758f52));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0d49fdecfd83acbc0c4e403a4b96d04542dbd03465708bb6e26e3eec1df502c4), uint256(0x1b9faa4cce510ffac3f5bac947b0cf375c9673a62a36e9ec1ad639f13b3afe13));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1c883e86b2a78076c2689e582d62b287d860b64146992da4dd4ff9a83ca15546), uint256(0x083fcc4790f5388e1f4adf19872074ad30c08da0c99a0fc86e70a5a333874ead));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x301d1e2361ee84c760c0d5ef1f723295a4c1d61bf4fd5563e57fbbe988a1bf65), uint256(0x058343cdd3b90d78b43fe22d1792d1fdf8302202e643562acc392be64fc58855));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0d02b9fa1271bb7eb144bd922643ecceafcc875daeb0b7b2a2cd0acd28b87439), uint256(0x20823be515ac15995c32c9e0d87e5ed36180495e3089ecf0fe91c9a94354777f));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0892120d29df7600aaf1082412ef7a84d0723403f4dd85d3907822ada61e109d), uint256(0x06ec95d25300cc5c9651e9e644398d88e47465eef935fa74c542e53e0c19e2f4));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x131ee770d72751180e8659b441e1f0eb2b58dce91bae10e5df814cb4a2f78b3f), uint256(0x093aac6c8d52e2403d827b336049fa0d124fadb90d8d807c1bb77c2115704043));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2b619ea47d6fc4b345145e96b2559105964860611ec57ecd013beb9401abe824), uint256(0x2a246e8f44fc9c153a13fd275c936b1acb54af1d97fbbf6c7239a01722395824));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x29ef746ee1fbec745928abb2cb22e6f44e34102d319bb44ef9be044aa99f9d66), uint256(0x20277eccf8c48f6a9ca9db480b2ca508321865cf1275562138a568c30609c583));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x278683da5bd1887f54c4b4176d78f1fbd38f7f330711abd9655ae15c31a2685d), uint256(0x0b7fa39d717f55f3bb9585828696a15f7e05dd25fc3259a4793f69089ac1af7b));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x12778ba9f0564ae59eaa73f801c9021534a30646f4ccb12c27730fb3a2694e08), uint256(0x24a0cad0d1ce129b70cdfc15385357d8636e7db642a9678830dfae514b96d420));
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
