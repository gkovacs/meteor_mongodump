# copies all collections and documents from mongourl_src to mongourl_dst
# mongourl_src defaults to mongodb://localhost:27018/default
# mongourl_dst defaults to mongodb://localhost:27017/default
# can use ssh tunnel to make remote host accessible on port 27017
# ssh -L 27018:localhost:27017 user@remotehost

require! asyncblock

require! {
  async
  'mongo-uri'
  levn
  optionator
  shelljs: {exec}
  mongodb: {MongoClient}
}

option_parser = optionator {
  options:
    * option: 'src'
      alias: 's'
      type: 'String'
      description: 'source mongo url'
      default: 'mongodb://localhost:27018/default'
    * option: 'dst'
      alias: 'd'
      type: 'String'
      description: 'destination mongo url'
      default: 'mongodb://localhost:27017/default'
    * option: 'help'
      alias: 'h'
      type: 'Boolean'
      description: 'display help'
}

options = option_parser.parseArgv process.argv
if options.help?
  console.log option_parser.generateHelp!
  process.exit!

mongourl_src = options.src
mongourl_dst = options.dst

console.log 'mongourl_src: ' + mongourl_src
console.log 'mongourl_dst: ' + mongourl_dst

# we will eventually want to be able to query based on timestamp
# http://stackoverflow.com/questions/11192136/mongodb-range-queries-on-insertion-time-with-id-and-objectid

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

all_collections = listcollections(mongourl_src)
console.log 'collections:'
console.log all_collections

if all_collections.length == 0
  console.log 'no collections to dump'
  process.exit()

getdb_src = (callback) ->
  err, db <- MongoClient.connect mongourl_src
  if err
    console.log 'error getting mongodb'
  else
    callback db

getdb_dst = (callback) ->
  err, db <- MongoClient.connect mongourl_dst
  if err
    console.log 'error getting mongodb'
  else
    callback db

getcollection_src = (collection_name, callback) ->
  db <- getdb_src!
  callback db.collection(collection_name), db

getcollection_dst = (collection_name, callback) ->
  db <- getdb_dst!
  callback db.collection(collection_name), db

copy_collection_orig = (collection_name, callback) ->
  console.log collection_name
  collection_src, db_src <- getcollection_src collection_name
  collection_dst, db_dst <- getcollection_dst collection_name
  err1, docs_src <- collection_src.find({}).toArray!
  err2, docs_dst <- collection_dst.find({}, {_id: 1}).toArray!
  dest_ids = {[x._id, true] for x in docs_dst}
  docs_src_new = [x for x in docs_src when not dest_ids[x._id]?]
  if docs_src_new.length == 0
    db_src.close!
    db_dst.close!
    return callback?!
  err3, result <- collection_dst.insertMany docs_src_new
  db_src.close!
  db_dst.close!
  return callback?!

copy_collection = (collection_name, callback) ->
  console.log collection_name
  collection_src, db_src <- getcollection_src collection_name
  collection_dst, db_dst <- getcollection_dst collection_name
  err2, docs_dst <- collection_dst.find({}, {_id: 1}).toArray!
  dest_ids = {[x._id.toString(), true] for x in docs_dst}
  asyncblock (flow) ->
    have_more = true
    num_skipped = 0
    batch_size = 1000
    while have_more
      docs_src = flow.sync collection_src.find({}).skip(num_skipped).limit(batch_size).toArray(flow.callback!)
      if not docs_src? or docs_src.length == 0
        have_more = false
        break
      num_skipped += batch_size
      docs_src_new = [x for x in docs_src when not dest_ids[x._id.toString()]?]
      if docs_src_new.length == 0
        continue
      flow.sync collection_dst.insertMany(docs_src_new, {}, flow.callback!)
    db_src.close!
    db_dst.close!
    return callback?!

async.eachSeries all_collections, (collection_name, donecb) ->
  if collection_name.startsWith('system.')
    return donecb!
  copy_collection collection_name, donecb
