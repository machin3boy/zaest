const PythonShell = require('python-shell').PythonShell;
const express = require('express');
const app = express();
const cors = require('cors');
const execSync = require('child_process').execSync;
const fs = require('fs');
const JSONBig = require('json-bigint');
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
    const proofLocation = "../../ZoKrates/onboarding_hashes_params/proof.json"
    const proofCommandOutput = execSync(proofCommand).toString();
    
    console.log(r);   
    console.log(proofCommandOutput);

    let proof = JSONBig.stringify(JSONBig.parse(fs.readFileSync(proofLocation, 'utf8')));
    console.log("proof index.js:" + proof);
    res.setHeader('Content-Type', 'application/json');
    res.send(proof);
});

app.get('/', (req, res) =>{
    res.send("Server is live");
    console.log("Server is live");
})

app.listen(PORT, () => {
    console.log(`App is listening at http://localhost:${PORT}`)
})
