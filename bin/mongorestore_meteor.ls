require! {
  fs
  'mongo-uri'
}

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

{exec} = require 'shelljs'

meteorsite = process.argv[2]
if not meteorsite?
  console.log 'need to provide meteorsite'
  process.exit()

dumpdir = process.argv[3]
if not dumpdir?
  console.log 'need to provide dumpdir'
  process.exit()

if meteorsite.indexOf('.meteor.com') == -1
  meteorsite = meteorsite + '.meteor.com'
meteorsitebase = meteorsite.split('.meteor.com').join('')

if not fs.existsSync(dumpdir)
  console.log 'dumpdir does not exist: ' + dumpdir
  process.exit()

mongourl = exec("meteor mongo --url #{meteorsite}").output.trim()

console.log 'mongourl: ' + mongourl

if mongourl.indexOf('mongodb://') != 0
  console.log 'mongourl does not begin with mongodb://'
  process.exit()

collections = process.argv[4]
if collections?
  collections = levn.parse '[String]', collections

mkrestore = (uri, dumppath) ->
  login = mongo-uri.parse uri
  host = login['hosts'][0] + ':' + login['ports'][0]
  db = login['database']
  user = login['username']
  passwd = login['password']
  #exec('mongoexport -h ' + host + ' -d ' + db + ' -u ' + user + ' -p ' + passwd + " -c " + collection + " -o '" + outfile + "'")
  if not collections?
    exec('mongorestore --drop --host ' + host + ' --db ' + db + ' --username ' + user + ' --password ' + passwd + " '" + dumppath + "'")
  else
    for collection in collections
      exec('mongorestore --drop --host ' + host + ' --db ' + db + ' --collection ' + collection + ' --username ' + user + ' --password ' + passwd + " '" + dumppath + "/#{collection}.bson'")

for dbpath in fs.readdirSync(dumpdir)
  console.log dumpdir + '/' + dbpath
  mkrestore mongourl, "#{dumpdir}/#{dbpath}"
