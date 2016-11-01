request = require 'request'
fs = require 'fs'
props = require 'props'
crypto = require 'crypto'
client = require 'cheerio-httpcli'

module.exports = (robot) ->
  ERR_MSG = 'error'

  md5hex = (src)->
    md5hash = crypto.createHash('md5')
    md5hash.update(src, 'binary')
    return md5hash.digest('hex')

  loadJSON = ->
    try
      json = fs.readFileSync('./data/test.json', 'utf8')
      return props(json)
    catch err
      return err

  checkUpdate = (title, str) ->
    try
      hash = fs.readFileSync('./tmp/'+ md5hex(title)).toString()
      newHash = md5hex(str)
      if (hash is newHash) or (hash is '')
        return false
      else
        return true
    catch err
      console.log(err)
      return false

  saveHex = (title, str) ->
    try
      json = fs.writeFileSync('./tmp/'+ md5hex(title),md5hex(str))
    catch err
      console.log(err)
      return err

  checkPages = (client, pages) ->
    page = pages.shift()
    client.fetch(page.url)
    .then (result) ->
      console.info(page.url)
      console.info(page.name)
      res = checkUpdate(page.url, result.$('#'+page.id).text())
      console.log(res)
      saveHex(page.url, result.$('#'+page.id).text())
      if pages.length is 0
        return
      checkPages(client, pages)
    .catch (err) ->
      console.log(err)

  loggedIn = (client, json) ->
    if json.pages.length < 1
      return true
    console.log(client.cookies)
    console.log(client)
    client.fetch(json.pages[0].url)
    .then (result) ->
      if result.$('#'+json.form_name)?
        return false
      else
        return true


  robot.respond /check$/i, (msg) ->
    if not client?
      console.log(client)
      console.log("hoge")
    json = loadJSON()
    msg.reply(json)
    client.fetch(json.url)
    .then (result) ->
      if result.response.statusCode isnt 200
        throw 'server fail'
      loginInfo = {}
      loginInfo[json.id_form_name] = json.id
      loginInfo[json.password_form_name] = json.password
      result.$('#'+ json.form_id).submit loginInfo
    .then (result) ->
      # ログインに成功していればログインページから移動するはず
      if result.response.request.href is json.url
        console.log(result)
        throw 'login fail'
    .then ->
      checkPages(client, json.pages)
    .then ->
      console.info('finish')
    .catch (err) ->
      console.log(err)
    .finally ->
      client.reset()