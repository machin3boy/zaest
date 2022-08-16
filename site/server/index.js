const PythonShell = require('python-shell').PythonShell;
const express = require('express');
const app = express();
const cors = require('cors');
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

app.get('/', (req, res) =>{
    res.send("Server is live");
    console.log("Server is live");
})

app.listen(PORT, () => {
    console.log(`App is listening at http://localhost:${PORT}`)
})
