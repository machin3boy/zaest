
const express = require('express')
const app = express()
const PORT = 3000

app.get('/test', (req, res) =>{
    res.send("test");
    console.log("test");
})

app.listen(PORT, () => {
    console.log(`App is listening at http://localhost:${PORT}`)
})
