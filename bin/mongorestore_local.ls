require! {
  fs
  'mongo-uri'
}

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

{run, exec} = require 'execSync'

dumpdir = process.argv[2]
if not dumpdir?
  console.log 'need to provide dumpdir'
  process.exit()

if not fs.existsSync(dumpdir)
  console.log 'dumpdir does not exist: ' + dumpdir
  process.exit()

mongourl = 'mongodb://localhost:27017'
meteorsite = meteorsitebase = 'local'

console.log 'mongourl: ' + mongourl

mkrestore = (uri, dumppath) ->
  login = mongo-uri.parse uri
  host = login['hosts'][0] + ':' + login['ports'][0]
  #run('mongoexport -h ' + host + ' -d ' + db + ' -u ' + user + ' -p ' + passwd + " -c " + collection + " -o '" + outfile + "'")
  run('mongorestore --drop --host ' + host + " '" + dumppath + "'")

for dbpath in fs.readdirSync(dumpdir)
  console.log dumpdir + '/' + dbpath
  mkrestore mongourl, "#{dumpdir}/#{dbpath}"
