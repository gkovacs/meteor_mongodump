require! {
  'mongo-uri'
}
{exec} = require 'shelljs'
{spawn} = require 'child_process'

meteorsite = process.argv[2]
if not meteorsite?
  console.log 'must provide meteor site'
  process.exit()
if meteorsite.indexOf('.meteor.com') == -1
  meteorsite = meteorsite + '.meteor.com'

mongourl = exec("meteor mongo --url #{meteorsite}").stdout.trim()

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
