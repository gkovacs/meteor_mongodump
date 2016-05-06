require! {
  fs
  'mongo-uri'
  sysexec
  glob
}

{exec} = require 'shelljs'

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

herokusite = process.argv[2]
if not herokusite?
  console.log 'need to provide herokusite'
  process.exit()

herokusite = herokusite.split('.herokuapp.com').join('')

mongourl = exec("heroku config:get MONGODB_URI --app #{herokusite}").output.trim()
if mongourl == ''
  mongourl = exec("heroku config:get MONGOLAB_URI --app #{herokusite}").output.trim()
console.log 'mongourl: ' + mongourl


dumpdir = process.argv[3]
if not dumpdir?
  console.log 'need to provide dumpdir'
  process.exit()

if not fs.existsSync(dumpdir)
  console.log 'dumpdir does not exist: ' + dumpdir
  process.exit()

#collections = process.argv[4]
#if collections?
#  collections = levn.parse '[String]', collections

mkrestore = (uri, dumppath) ->
  login = mongo-uri.parse uri
  host = login['hosts'][0] + ':' + login['ports'][0]
  db = login['database']
  user = login['username']
  passwd = login['password']
  collection = dumppath.split('/')[-1 to][0].split('.json').join('')
  #exec('mongoexport -h ' + host + ' -d ' + db + ' -u ' + user + ' -p ' + passwd + " -c " + collection + " -o '" + outfile + "'")
  console.log("mongoimport --username #{user} --password #{passwd} --jsonArray --upsert --host #{host} --db #{db} --collection #{collection} --file #{dumppath}")
  exec("mongoimport --username #{user} --password #{passwd} --jsonArray --upsert --host #{host} --db #{db} --collection #{collection} --file #{dumppath}")

for dbpath in glob.sync(dumpdir + '/*.json')
  console.log dbpath
  mkrestore mongourl, dbpath
