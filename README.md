
Vera is a Web3 project that allows parties to act as users onboarding encrypted data into a smart contract and decentralized storage medium such as IPFS or as verifiers that are able to request proof of ownership of certain data from users while abiding by the principle of least privilege. Using the smart contract that leverages zk-SNARK verifiers, users are able to verify that requesting verifiers have valid permissions to request certain types of data while verifiers are able to ascertain that a response to their requests for data originated from the user without breaching the integrity of the relevant data that was onboarded to the smart contract. Additionally, zk-SNARK verifiers enforce the condition that onboarded data by users into the smart contract or the decentralized storage medium is valid and correctly encrypted.

The applications of the above are that the smart contract can therefore act as the fabric for ubiquitous, privacy-preserving but law-abiding (or some other form of condition-abiding) computations through smart devices. The solution can therefore be leveraged for utilities such as transportation, identity verification, police records, banking and finance, pharmaceutical and medical needs, encrypted data storage, etc. Any device that can utilize the internet can essentially integrate the relevant Web3 functionality of the smart contract - such as a smart phone or smart ring. This device can then be used akin to a swiss army knife for smart city needs - such as tapping the ring at a transportation gate, pharmacy terminal, or verifying a request to prove one's driving license is not expired to a police officer through the phone. 

By leveraging IPFS or an alternative decentralized storage medium, Vera can be extended to function as a multi-chain utility while also having a reliable censorless data storage layer. Hosting the Web3 portal through IPFS will also make it more resistant to downtime and far more secure. Another advantage of IPFS is that utilizing it as the primary storage medium for encrypted information allows for infinite scaling with regards to how much data can be stored. Requests and responses can also be non-persisting on IPFS, unlike most blockchains, and as a consequence requests and responses can be ephemeral albeit the data requests and repsonses are already ephemeral in the sense that they are only valid within some time limit. 

Of course, some of the proposed use-cases of this protocol are highly contingent upon stronger enforced security measures (for example: biometric scans at airports to prove identity potentially). This is where a technology such as Chainlink's External Adapters can come to aid. Chainlink's External Adapters functionality allow for integrating 2FA/3FA/etc. into the protocol's smart contract by leveraging extensible APIs that can generate one-time 2FA keys, validate fingerprint scans at a particular moment in time through trusted hardware, etc.

Chainlink's prospective advantages to the protocol also include the possibility to simplify and scale the ZKP portions of the protocol more easily (although the protocol outlined as is infinitely scaleable, Chainlink can allow for a number of optimizations through off-chain computations).

The design of the protocol is presented in the file docs/Vera.pdf.
