# Copyright 2016, All Rights Reserverd
# Hong Liu <hong.x.liu@oracle.com>
module.exports = (app, exadata) -> 
    fs = require('fs')
    lazyDB = {
        reimage_install: {
            active: false,
            data: []
        },
        reimage_config: {
            active: false,
            data: []
        },
        upgrade: {
            active: false,
            data: []
        },
        rdstest: {
            active: false,
            data: []
        }
    }

    exec = require('child_process').exec
    execFile = require('child_process').execFile

    app.get('/api/config', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        res.status(200).send(exadata)
    )
    app.get('/api/log', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        fileList = fs.readdirSync(exadata.log_loc)
        res.status(200).send(fileList)
    )
    app.get('/api/log/:logfile', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        data = fs.readFileSync(exadata.log_loc + req.params.logfile)
        res.status(200).send(data)
    )
    app.get('/api/user', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        res.status(200).send(req.requestee)
    )
    app.get('/api/longcmd/:cmd/start', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        mydb = lazyDB[req.params.cmd]
        if mydb.active
            return res.status(200).send("This command is already running.")
        mydb.active = true
        mydb.data = []
        logfile = exadata.log_loc + req.params.cmd + "." + (new Date()).toLocaleString().replace(/\//g, "-").replace(/ /g, "")

        fs.writeFileSync(logfile, req.params.cmd + ":\n", {flag: "a+"})
        if req.params.cmd == "reimage_install"
            longcmd = execFile("./reimage_install.sh", [req.query.nodes, req.query.cells, req.query.image_ver], {cwd: __dirname + "/../script"})
            cmd = "cd " + __dirname + "/../script; ./reimage_install.sh " + req.query.nodes + " " + req.query.cells + " " + req.query.image_ver + "\n"
            fs.writeFileSync(logfile, cmd, {flag: "a+"})
        if req.params.cmd == "reimage_config"
            longcmd = execFile("./reimage_config.sh", [req.query.nodes, req.query.cells, req.query.image_ver, req.query.type, req.query.config], {cwd: __dirname + "/../script"})
            cmd = "cd " + __dirname + "/../script; ./reimage_config.sh " + req.query.nodes + " " + req.query.cells + " " + req.query.image_ver + " " + req.query.type + " " + req.query.config + "\n"
            fs.writeFileSync(logfile, cmd, {flag: "a+"})
        if req.params.cmd == "upgrade"
            longcmd = execFile("./upgrade.sh", {cwd: __dirname + "/../script"})
            fs.writeFileSync(logfile, "cd " + __dirname + "/../script; ./upgrade.sh\n", {flag: "a+"})
        if req.params.cmd == "rdstest"
            longcmd = execFile("./rdstest.sh", {cwd: __dirname + "/../script"})
            fs.writeFileSync(logfile, "cd " + __dirname + "/../script; ./rdstest.sh\n", {flag: "a+"})

        longcmd.stdout.on("data", (data) ->
            mydb.data.push(data.toString())
            fs.writeFileSync(logfile, data.toString(), {flag: "a+"})
        )
        longcmd.stdout.on("close", (data) ->
            mydb.active = false
        )
        res.status(200).send("Started")
    )
    app.get('/api/longcmd/:cmd/data', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        mydb = lazyDB[req.params.cmd]
        res.status(200).send(mydb.data.join(""))
    )
    app.get('/api/longcmd/:cmd/data/done', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        mydb = lazyDB[req.params.cmd]
        res.status(200).send(!mydb.active)
    )
    app.get('/api/longcmd/:cmd/data/pages', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        mydb = lazyDB[req.params.cmd]
        res.status(200).send(mydb.data.length.toString())
    )
    app.get('/api/longcmd/:cmd/data/:page', (req, res) ->
        if !req.requestee
            return res.status(401).send("access denied")
        mydb = lazyDB[req.params.cmd]
        res.status(200).send(mydb.data[req.params.page])
    )
