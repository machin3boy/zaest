<template>
    <div class="p-20 text-xl flex-col">
            <p class="my-5" align="justify">
            Zaest is a Web3 project that allows parties to act as users onboarding encrypted data into a smart contract and/or a decentralized storage medium such as IPFS or as verifiers that are able to request proof of ownership of certain data from users while abiding by the principle of least privilege. Using the smart contract that leverages zk-SNARK verifiers, users are able to verify that requesting verifiers have valid permissions to request certain types of data while verifiers are able to ascertain that a response to their requests for data originated from the user without breaching the integrity of the relevant data that was onboarded to the smart contract. Additionally, zk-SNARK verifiers enforce the condition that onboarded data by users into the smart contract or the decentralized storage medium is valid and correctly encrypted. Onboarded data is updated through validated requests from either the user or some verifier.
            </p>


            <p class="my-5" align="justify">
            The applications of the above are that the smart contract can therefore act as the fabric for ubiquitous, privacy-preserving but law-abiding (or some other form of condition-abiding) computations through smart devices. The solution can therefore be leveraged for utilities such as transportation, identity verification, police records, banking and finance, pharmaceutical and medical needs, encrypted data storage, etc. Any device that can utilize the internet can essentially integrate the relevant Web3 functionality of the smart contract - such as a smart phone or smart ring. This device can then be used akin to a swiss army knife for smart city needs - such as tapping the ring at a transportation gate, pharmacy terminal, or verifying a request to prove one's driving license is not expired to a police officer through the phone.
            </p>


            <p class="my-5" align="justify">
            By leveraging IPFS or an alternative decentralized storage medium, Zaest can be extended to function as a multi-chain utility while also having a reliable censorless data storage layer. Hosting the Web3 portal through IPFS will also make it more resistant to downtime and far more secure. Another advantage of IPFS is that utilizing it as the primary storage medium for encrypted information allows for infinite scaling with regards to how much data can be stored. Requests and responses can also be non-persisting on IPFS, unlike blockchains, and as a consequence requests and responses can be ephemeral albeit the data requests and repsonses are already ephemeral in the sense that they are only valid within some time limit.
            </p>

            <p class="my-5" align="justify">
            Of course, some of the proposed use-cases of this protocol are highly contingent upon stronger enforced security measures (for example: biometric scans at airports to prove identity potentially). This is where a technology such as Chainlink's External Adapters can come to aid. Chainlink's External Adapters functionality allow for integrating 2FA/3FA/etc. into the protocol's smart contract by leveraging extensible APIs that can generate one-time 2FA keys, validate fingerprint scans at a particular moment in time through trusted hardware, etc.
            </p>

            <p class="my-5" align="justify">
            Chainlink's prospective advantages to the protocol also include the possibility to simplify and scale the ZKP portions of the protocol more easily (although the protocol outlined as is is infinitely scaleable, Chainlink can allow for a number of optimizations through off-chain computations).
            </p>

            <p class="my-5" align="justify">
            The design of the protocol is presented in the file /docs/Zaest.pdf availabe at <el-link type="primary" class="text-xl">www.github.com/machin3boy/zaest</el-link>.
            </p>

            <p class="my-5" align="justify">
            If you intend to install the project on your machine please note that the verification and proving keys are not present in the repo as they are large files. To access the verification and proving keys for each of the five individual circuit components please retrieve them from the following IPFS CIDs:
            </p>
            
            <div class="ml-20">
                    <li>
                        bafybeigx3mowmrbetae2m46rocpdi6staojsma6nzyn2u5bpmekssdmhtu
                    </li>
                    <li>                
                        bafybeiceajv3dsqma3wu6lr66dq7exiw3ofrrux4qpgidys3xgu6imc3iq
                    </li>
                    <li>  
                        bafybeibclt3iw325nw24f3ztewiako3k52imdpvnpfryhhb76zbvwlesbu
                    </li>
                    <li>    
                        bafybeieqjlygtdwmpo5bpuzrvqv3p3gwxa5hnp3wehays4j6z3u7etdm7m
                    </li>
                    <li>   
                        bafybeihtuzahzj7y32ngkux226yq5vrlirxa7auzbolb3f67qhc26zsfke
                    </li>
                    <li>    
                        bafybeig2av5geiooe5wdh2rzk3wr2bildp5wofc63ubryu2ectdsm2knhe
                    </li>
                    <li>    
                        bafybeigerd7x6dltb5knj4xsvmh5ypgobxp4bqvilosgzac67xkrx7zpvu
                    </li>
                    <li>    
                        bafybeigatnahftav55ajmunugmnxco7lcbj5lyayivkpzmbwosen35avbu
                    </li>
                    <li> 
                        bafybeiavnn2ezvflzgei2v2h5xzasyvb32lmnzaxm3rbjsbrmpegqy3wgi
                    </li>
                    <li>    
                        bafybeibwwsbwd5dmkyrxiv4jriksu63426uagubsg4fbzhx334hy6l2w44
                    </li>
            </div>

            <p class="my-5" align="justify">
            These keys are to be housed in the corresponding directories in /ZoKrates/. They are as follows: 
            </p>
            <div class="ml-20">
                <li>        
                    /ZoKrates/onboarding_aes_params/
                </li>
                <li>    
                    /ZoKrates/onboarding_hashes_params/
                </li>
                <li>
                    /ZoKrates/onboarding_ipfs_params/
                </li>
                <li>
                    /ZoKrates/ownership_hashes_params/
                </li>
                <li>
                    /ZoKrates/onboarding_ipfs_params/p
                </li>
            </div>
            
            <p class="my-5" align="justify">
            To install and run this project you can refer to the README.md in the /site/ directory of the repo.
            </p>

            <p>
            The contract address of the V1 prototype is given here: 0x5B3fB9655fab94D5A9491Ed3f8a4620afBA874A5
            </p>

            <p class="my-5" align="justify">
            A prototype is temporarily live on this site, however the RAM available is only 512MB and as a consequence generating ZKPs can be very time-consuming. When accessing the prototype please ensure that your wallet is connected as that will initialize the contract instance. Following this, please ensure that you onboard secondary keys with <el-link type="primary" class="text-xl">www.zaestprototype.site/#/secondarykeys</el-link> prior to using the dApp.
            </p>

    </div>
</template>