# Copyright 2016, All Rights Reserverd
# Hong Liu <hong.x.liu@oracle.com>
path = require('path')
express = require('express')
bodyParser = require('body-parser')
cookieParser = require('cookie-parser')

app = express()
app.use(bodyParser.json({limit: '50mb'}))
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }))
app.use(cookieParser())

app.use(express.static(path.join(__dirname, './www')))

app.get('/exadata', (req, res) ->
    res.sendFile(path.join(__dirname, './www/exadata.html'))
)
app.get('/auth', (req, res) ->
    res.sendFile(path.join(__dirname, './www/auth.html'))
)
app.get('/test', (req, res) ->
    res.sendFile(path.join(__dirname, './www/test.html'))
)

require('./api')(app)
app.listen(3000)
