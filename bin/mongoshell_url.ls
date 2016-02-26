require! {
  'mongo-uri'
}
{spawn} = require 'child_process'

mongourl = process.argv[2]
if not mongourl?
  console.log 'must provide mongourl'
  process.exit()
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
