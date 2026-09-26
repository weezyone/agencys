const {MongoMemoryServer}=require('mongodb-memory-server');
(async()=>{const m=await MongoMemoryServer.create({instance:{port:27017,dbPath:__dirname+'/data',storageEngine:'wiredTiger'}});console.log('MONGO READY',m.getUri());setInterval(()=>{},1<<30)})().catch(e=>{console.error(e);process.exit(1)});
