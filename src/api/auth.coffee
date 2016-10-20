# Copyright 2016, All Rights Reserverd
# Hong Liu <hong.x.liu@oracle.com>
module.exports = (app, exadata) ->
    crypto = require('crypto')
    marked = require('marked')
    zxcvbn = require('zxcvbn')
    sanitize = require('mongo-sanitize')

    isString = (value) ->
        return typeof value == "string"

    computeHash = (password, salt, callback) ->
        crypto.pbkdf2(password, salt, 10000, 512, 'sha512', callback)

    randomString = () ->
        b64 = crypto.randomBytes(32).toString('base64')
        return b64.replace(/\/|\+|=/g, "")

    generateToken = (user, context, is_parent = false, duration = 60 * 60 * 24) -> 
        token = randomString()
        current_time = parseInt((new Date()).getTime()/1000)
        myUser = exadata.users.find((e) ->
            e.email == user.email
        )
        myUser.tokens.push(
            {
                "value": token
                "context": context
                "expiration": current_time + duration
            }
        )
        return token

    app.post('/api/auth/signin', (req, res) ->
        if !req.body.email or !req.body.password
            return res.status(400).send("Missing email or password.")
        if !isString(req.body.email) or !isString(req.body.password)
            return res.status(400).send("Malformed email or password.")

        user = exadata.users.find((e) ->
            e.email == sanitize(req.body.email)
        )
        if !user
            return res.status(401).send("Incorrect email.")

        user.salt = sanitize(req.body.email)
        computeHash(req.body.password, user.salt, (err, hash) ->
            is_user = hash.toString('base64') == user.password
            if is_user
                return res.status(200).send({
                    "message": "success"
                    "auth_token": generateToken(user, req.headers, false, 60 * 60 * 24)
                })
            return res.status(401).send("Incorrect password.")
        )
    )

    app.post('/api/auth/signup', (req, res) ->
        if !req.body.email or !req.body.password
            return res.status(400).send("Missing email or password.")
        if !isString(req.body.email) or !isString(req.body.password)
            return res.status(400).send("Malformed email or password.")

        if req.body.password.length < 8 || req.body.password.match(/^[0-9]+$/) != null || req.body.password.match(/^[A-z]+$/) != null
            message = ""
            message += "Your password must have at least 8 characters and must contain both numbers and letters. "
            return res.status(400).send(message)

        user = exadata.users.find((e) ->
            e.email == sanitize(req.body.email)
        )
        if user
            return res.status(400).send("Email already exists.")

        salt = sanitize(req.body.email)
        password = req.body.password
        computeHash(password, salt, (err, hash) =>
            return res.status(200).send(hash.toString('base64'))
        )
    )

