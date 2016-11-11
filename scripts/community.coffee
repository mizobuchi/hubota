request = require 'request'
fs = require 'fs'
crypto = require 'crypto'
client = require 'cheerio-httpcli'
cronJob = require('cron').CronJob

module.exports = (robot) ->
  ERR_MSG = 'error'

  md5hex = (src)->
    md5hash = crypto.createHash('md5')
    md5hash.update(src, 'binary')
    return md5hash.digest('hex')

  loadJSON = ->
    try
      json = fs.readFileSync('./data/community.json', 'utf8')
      return JSON.parse(json)
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
      robot.logger.error err
      return false

  saveHex = (title, str) ->
    try
      json = fs.writeFileSync('./tmp/'+ md5hex(title),md5hex(str))
    catch err
      robot.logger.error err
      return err

  sendToIfttt = (msg, json) ->
    try
      client.fetch('https://maker.ifttt.com/trigger/' + json.ifttt_event + '/with/key/' + json.ifttt_key + '?value1=' + encodeURIComponent(msg))
      .then (result) ->
        robot.logger.debug result
    catch err
      robot.logger.error err
      return err

  checkPages = (client, pages, json, opt_pointer) ->
    this.pointer = opt_pointer || 0
    page = pages[pointer]
    client.fetch(page.url)
    .then (result) ->
      robot.logger.info page.name
      if page.exclude_class?
        result.$('.' + page.exclude_class).remove()
      res = checkUpdate(page.url, result.$('#'+page.id).text())
      if res is true
        robot.logger.info page.name + 'is updated'
        sendToIfttt(page.name, json)
      saveHex(page.url, result.$('#'+page.id).text())
      pointer += 1
      if pointer == pages.length
        return
      checkPages(client, pages, json, pointer)
    .catch (err) ->
      robot.logger.error err

  checkLoggedIn = (client, json) ->
    if json.pages.length < 1
      return true
    client.fetch(json.pages[0].url)
    .then (result) ->
#      if result.$('#'+json.form_id).length > 0
      if result.response.request.href.indexOf(json.err_url) is 0
        robot.logger.info 'loggedIn = false'
        return false
      else
        robot.logger.info 'loggedIn = true'
        return true

  logIn = (client, json) ->
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
        robot.logger.error result
        throw 'login fail'
      else
        robot.logger.info 'logIn!'

  json = loadJSON()

  robot.respond /check$/i, (msg) ->
    json = loadJSON()
    checkLoggedIn(client, json)
    .then (result) ->
      if not result
        logIn(client, json)
    .then ->
      checkPages(client, json.pages, json)
    .then ->
      console.info('finish')
    .catch (err) ->
      console.log(err)
    .finally ->
      msg.reply('')

  communityCron = new cronJob({
    cronTime: json.cron_time
    onTick: ->
      checkLoggedIn(client, json)
      .then (result) ->
        if not result
          logIn(client, json)
      .then ->
        checkPages(client, json.pages, json)
      .then ->
        robot.logger.info 'finish'
      .catch (err) ->
        robot.logger.error err
      .finally ->
        msg.reply('')
    start: true
  })
