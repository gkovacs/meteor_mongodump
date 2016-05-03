require! {
  fs
  levn
  'mongo-uri'
}

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

{exec} = require 'shelljs'

mongourl = process.argv[2]
if not mongourl?
  console.log 'need to provide mongourl'
  process.exit()

dumpdir = process.argv[3]
if not dumpdir?
  console.log 'need to provide dumpdir'
  process.exit()

if not fs.existsSync(dumpdir)
  console.log 'dumpdir does not exist: ' + dumpdir
  process.exit()

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
    exec('mongorestore --host ' + host + ' --db ' + db + ' --username ' + user + ' --password ' + passwd + " '" + dumppath + "'")
  else
    for collection in collections
      exec('mongorestore --host ' + host + ' --db ' + db + ' --collection ' + collection + ' --username ' + user + ' --password ' + passwd + " '" + dumppath + "/#{collection}.bson'")

for dbpath in fs.readdirSync(dumpdir)
  console.log dumpdir + '/' + dbpath
  mkrestore mongourl, "#{dumpdir}/#{dbpath}"
