require! {
  fs
  'mongo-uri'
  sysexec
  glob
}

# usage:
# meteor_mongorestore crowdresearch path_to_some_dump

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

#collections = process.argv[4]
#if collections?
#  collections = levn.parse '[String]', collections

mkrestore = (uri, dumppath) ->
  login = mongo-uri.parse uri
  host = login['hosts'][0] + ':' + login['ports'][0]
  db = login['database']
  user = login['username']
  passwd = login['password']
  #exec('mongoexport -h ' + host + ' -d ' + db + ' -u ' + user + ' -p ' + passwd + " -c " + collection + " -o '" + outfile + "'")
  sysexec('mongoimport --host ' + host + ' --db ' + db + " '" + dumppath + "'")

for dbpath in glob.sync(dumpdir + '/*.json')
  mkrestore mongourl, dbpath
