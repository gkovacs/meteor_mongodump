require! {
  'mongo-uri'
}
{exec} = require 'shelljs'
{spawn} = require 'child_process'

herokusite = process.argv[2]
if not herokusite?
  console.log 'need to provide herokusite'
  process.exit()

herokusite = herokusite.split('.herokuapp.com').join('')

mongourl = exec("heroku config:get MONGOLAB_URI --app #{herokusite}").output.trim()

if mongourl.indexOf('mongodb://') != 0
  console.log 'mongourl does not begin with mongodb://'
  process.exit()

login = mongo-uri.parse mongourl

host = login['hosts'][0] + ':' + login['ports'][0]
db = login['database']
user = login['username']
passwd = login['password']

#shellcmd = "mongo -u '#{user}' -p '#{passwd}' '#{host}/#{db}'"
spawn 'mongo', ['-u', user, '-p', passwd, "#{host}/#{db}"], {stdio: 'inherit'}
