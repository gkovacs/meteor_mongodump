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

mkrestore = (uri, dumppath) ->
  login = mongo-uri.parse uri
  if not login.database?
    login.database = 'default'
  host = login['hosts'][0] + ':' + login['ports'][0]
  #exec('mongoexport -h ' + host + ' -d ' + db + ' -u ' + user + ' -p ' + passwd + " -c " + collection + " -o '" + outfile + "'")
  exec('mongorestore --drop --db #{login.database} --host ' + host + " '" + dumppath + "'")

for dbpath in fs.readdirSync(dumpdir)
  console.log dumpdir + '/' + dbpath
  mkrestore mongourl, "#{dumpdir}/#{dbpath}"
