# Copyright 2016, All Rights Reserverd
# Hong Liu <hong.x.liu@oracle.com>
module.exports = (app) -> 
    exadata = require("../../exadata.json")

    app.use("/api", (req, res, next) ->
        res.header("Cache-Control", "no-cache, no-store, must-revalidate")
        res.header("Pragma", "no-cache")
        res.header("Expires", 0)

        req.requestee = false
        if (req.headers['x-exadata-token'])
            req.requestee = exadata.users.find((u) ->
                u.tokens.find((t) ->
                    t.value == req.headers['x-exadata-token'] &&
                    t.expiration > parseInt((new Date()).getTime()/1000)
                )
            )
        next()
    )

    require('./auth')(app, exadata)
    require('./exadata')(app, exadata)
