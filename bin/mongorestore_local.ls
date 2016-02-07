require! {
  fs
  'mongo-uri'
}

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

{exec} = require 'shelljs'

dumpdir = process.argv[2]
if not dumpdir?
  console.log 'need to provide dumpdir'
  process.exit()

if not fs.existsSync(dumpdir)
  console.log 'dumpdir does not exist: ' + dumpdir
  process.exit()

mongourl = 'mongodb://localhost:27017/default'
meteorsite = meteorsitebase = 'local'

console.log 'mongourl: ' + mongourl

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
      exec('mongorestore --drop --host ' + host + ' --db ' + db + ' --collection ' + collection + ' --username ' + user + ' --password ' + passwd + " '" + dumppath + "'")

for dbpath in fs.readdirSync(dumpdir)
  console.log dumpdir + '/' + dbpath
  mkrestore mongourl, "#{dumpdir}/#{dbpath}"
