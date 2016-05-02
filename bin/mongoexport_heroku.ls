require! {
  fs
  'mongo-uri'
  levn
}
{exec} = require 'shelljs'

# usage:

datecmd = 'date'
if fs.existsSync('/usr/local/bin/gdate')
  datecmd = '/usr/local/bin/gdate'

curdate = exec(datecmd + ' --rfc-3339=seconds').output.split(' ').join('_').trim()

herokusite = process.argv[2]
if not herokusite?
  console.log 'need to provide herokusite'
  process.exit()

herokusite = herokusite.split('.herokuapp.com').join('')

dumpdir = [herokusite, curdate].join('_')

mongourl = exec("heroku config:get MONGODB_URI --app #{herokusite}").output.trim()
if mongourl == ''
  mongourl = exec("heroku config:get MONGOLAB_URI --app #{herokusite}").output.trim()
console.log 'mongourl: ' + mongourl

listcollections = (uri) ->
  login = mongo-uri.parse uri
  if login['hosts'][0] == 'localhost'
    login['hosts'][0] = '127.0.0.1'
  host = login['hosts'][0] + ':' + login['ports'][0]
  db = login['database']
  user = login['username']
  passwd = login['password']
  mongocmd = ['mongo']
  if user?
    mongocmd.push "--username #{user}"
  if passwd?
    mongocmd.push "--password #{passwd}"
  mongocmd.push "#{host + '/' + db} --eval 'db.getCollectionNames()'"
  mongocmdstr = mongocmd.join(' ')
  #console.log mongocmdstr
  return levn.parse '[String]', exec(mongocmdstr).output.trim().split('\n').filter((x) -> x.indexOf('MongoDB shell version') == -1 && x.indexOf('connecting to:') == -1).join('\n')

all_collections = listcollections(mongourl)
console.log 'collections:'
console.log all_collections

if all_collections.length == 0
  console.log 'no collections to dump'
  process.exit()

mkexport = (uri, collection) ->
  #login = json.loads(check_output("lsc parse_mongo_uri.ls '" + uri + "'", shell=True))
  login = mongo-uri.parse uri
  if not login.database?
    login.database = 'default'
  if login['hosts'][0] == 'localhost'
    login['hosts'][0] = '127.0.0.1'
  host = login['hosts'][0] + ':' + login['ports'][0]
  outfile = dumpdir + '/' + collection + '.json'
  exec('mongoexport --jsonArray -h ' + host + " --db #{login.database} -c " + collection + " -o '" + outfile + "'")
  #exec('mongodump -h ' + host + " --db #{login.database} -c " + collection + " -o '" + dumpdir + "'")

for collection in all_collections
  if collection.startsWith('system.')
    continue
  mkexport mongourl, collection