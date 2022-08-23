install ZoKrates & VueCLI on your machiine

to run project:

    in `client`, run `npm install` and `npm run serve` (to run client)

    in `server`, run `npm install` and `npm run dev` (to run both server and client) or `node index.js` to run only server

    obtain the keys required for the zokrates circuits from IPFS as specified
    in the main project description README.md and place them into the following 
    directories:
        onboarding_hashes_params
        onboarding_ipfs_params
        onboarding_aes_params
        ownership_hashes_params
        ownership_ipfs_params


*please note that currently the `url` parameter in `/site/server/index.js` references http://localhost:3001, this can be adjusted according to your needs. 
