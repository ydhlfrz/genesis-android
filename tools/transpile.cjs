const fs=require('fs'),path=require('path'),babel=require('@babel/core');
const source=fs.readFileSync(path.join(__dirname,'engine-source.js'),'utf8');
const out=babel.transformSync(source,{sourceType:'script',comments:false,assumptions:{iterableIsArray:true,setSpreadProperties:true},presets:[[require('@babel/preset-env'),{targets:{ie:'11'},modules:false,loose:true}]]}).code;
fs.writeFileSync(path.join(__dirname,'../app/src/main/assets/engine.js'),fs.readFileSync(path.join(__dirname,'polyfills.js'),'utf8')+'\n'+out);
console.log('Prepared interpreter-compatible character engine.');
