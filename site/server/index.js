const PythonShell = require('python-shell').PythonShell;
const express = require('express');
const app = express();
const cors = require('cors');
const execSync = require('child_process').execSync;
const fs = require('fs');
app.use(cors());
const PORT = 3001;

let python_process;

app.get('/aes', function(req, res) {
    let options = {
        mode: 'text',
        args: [req.query.aesKeyParam, req.query.aesDataParam, req.query.aesFunctionParam],
    };
    let pyshell = PythonShell.run('../../utils/aes.py', options, function(err, results){
        if(err)
            throw err;    
        res.send(results);       
    });
    python_process = pyshell.childProcess;
});

app.get("/rsaKeys", function(req, res) {
    let options = {
        mode: 'text',
        args: ['keys'],
    };
    let pyshell = PythonShell.run('../../utils/rsa.py', options, function(err, results){
        if(err)
            throw err;    
        res.send(results);       
    });
    python_process = pyshell.childProcess;
});

app.get("/rsa", function(req, res) {
    let options = {
        mode: 'text',
        args: [req.query.rsaKeyParam, req.query.rsaDataParam, req.query.rsaFunctionParam],
    };
    let pyshell = PythonShell.run('../../utils/rsa.py', options, function(err, results){
        if(err)
            throw err;    
        res.send(results);       
    });
    python_process = pyshell.childProcess;
});

app.get('/stopPython', function(req, res) {
    python_process.kill('SIGINT');
    res.send('Stopped');
 });

app.get('/zokratesOnboardingHashes', function(req, res) {
    const r = req.query;
    const proofCommand = "current_dir=$PWD; cd ../../ZoKrates/onboarding_hashes_params; " +
                     "zokrates compute-witness -a " + r.u + " " +  r.dA + " " + r.dB + 
                     " " + r.dC + " " +  r.dD + " " + r.up + " " + r.ar + " " + r.vA + 
                     " " + r.vB + " " + r.aA + " " + r.aB + " " + r.aC + " " + r.aD + 
                     " " + r.oA + " " + r.oB + " " + r.h_keyA + " " + r.h_keyB + " " + 
                     r.h_ruA + " " + r.h_ruB + " " + r.h_daA + " " + r.h_daB + 
                     "; zokrates generate-proof; cd $current_dir";                 
    const proofLocation = "../../ZoKrates/onboarding_hashes_params/proof.json";
    const proofCommandOutput = execSync(proofCommand).toString();
    
    console.log(r);   
    console.log(proofCommandOutput);

    let proof = JSON.stringify(JSON.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
});

app.get('/zokratesOnboardingAES', function(req, res) {
    const r = req.query;
    const proofCommand = "current_dir=$PWD; cd ../../ZoKrates/onboarding_aes_params; " + 
                         "zokrates compute-witness -a " + r.u + " " + r.dA + " " + r.dB + 
                         " " + r.dC + " " + r.dD + " " + r.aA + " " + r.aB + " " + r.aC + 
                         " " + r.aD + " " + r.h_keyA + " " + r.h_keyB + " " + r.h_dpA + 
                         " " + r.h_dpB + "; zokrates generate-proof; cd $current_dir";
    const proofLocation = "../../ZoKrates/onboarding_aes_params/proof.json";
    const proofCommandOutput = execSync(proofCommand).toString();

    console.log(r);
    console.log(proofCommandOutput);

    let proof = JSON.stringify(JSON.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
});

app.get('/', (req, res) =>{
    res.send("Server is live");
    console.log("Server is live");
})


app.get('/zokratesOnboardingIPFS', function(req, res) {
    const r = req.query;
    const proofCommand = "current_dir=$PWD; cd ../../ZoKrates/onboarding_ipfs_params; " + 
                         "zokrates compute-witness -a " + r.aA + " " + r.aB + " " + r.aC + 
                         " " + r.aD + " " + r.oA + " " + r.oB + " " + r.cA + " " + r.cB + 
                         " " + r.cC + " " + r.cD + " " + r.h_ipfs_d0 + " " + r.h_ipfs_d1 + 
                         "; zokrates generate-proof; cd $current_dir";
    const proofLocation = "../../ZoKrates/onboarding_ipfs_params/proof.json";
    const proofCommandOutput = execSync(proofCommand).toString();

    console.log(r);
    console.log(proofCommandOutput);

    let proof = JSON.stringify(JSON.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
});

app.get('zokratesOwnershipHashes', function(req, res) {
    const r = req.query;
    const proofCommand = "current_dir=$PWD; cd ../../ZoKrates/ownership_hashes_params; " + 
                         "zokrates compute-witness -a " + r.u + " " + r.dA + " " + r.dB + " "
                         + r.dC + " " + r.dD + " " + r.vA + " " + r.vB + " " + r.aA + " " + 
                         r.aB + " " + r.aC + " " + r.aD + " " + r.oA + " " + r.oB + " " + 
                         r.n + " " + r.h_keyA + " " + r.h_keyB + " " + r.h_txA + " " + 
                         r.h_txB + " " + r.h_daA + " " + r.h_daB + " " + r.h_dnA + " " + 
                         r.h_dnB + "; zokrates generate-proof; cd $current_dir";
    const proofLocation = "../../ZoKrates/ownership_hashes_params/proof.json";
    const proofCommandOutput = execSync(proofCommand).toString();

    console.log(r);
    console.log(proofCommandOutput);

    let proof = JSON.stringify(JSON.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
});

app.get('zokratesOwnershipIPFS', function(req, res) {
    const r = req.query;
    const proofCommand = "current_dir=$PWD; cd ../../ZoKrates/ownership_ipfs_params; " + 
                         "zokrates compute-witness -a " + r.e_rsA + " " + r.e_rsB + " " +
                         r.e_rsC + " " + r.e_rsD +  " " + r.cA + " " + r.cB + " " + r.cC +
                         " " + r.cD + " " + r.h_ipfs_pA + " " + r.h_ipfs_pB + 
                         "; zokrates generate-proof; cd $current_dir"; 
    const proofLocation = "../../ZoKrates/ownership_ipfs_params/proof.json";
    const proofCommandOutput = execSync(proofCommand).toString();

    console.log(r);
    console.log(proofCommandOutput);

    let proof = JSON.stringify(JSON.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
})

app.listen(PORT, () => {
    console.log(`App is listening at http://localhost:${PORT}`)
})
