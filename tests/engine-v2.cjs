const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const root=path.join(__dirname,'..');const ctx=vm.createContext({});vm.runInContext(fs.readFileSync(path.join(root,'tools/engine-source.js'),'utf8'),ctx);
const fixtures=JSON.parse(fs.readFileSync(path.join(root,'app/src/test/resources/fixtures.json'),'utf8'));
for(const f of fixtures){const actual=JSON.parse(ctx.nativeReconstruct(JSON.stringify(f.row)));assert.deepEqual(actual,f.character);assert.equal(ctx.nativePrompt(JSON.stringify(actual)),f.prompt);}
const spec=JSON.parse(fs.readFileSync(path.join(root,'standards/character-standard-v2.json')));const names=['Common','Rare','Super Rare','Epic','Mythic'];let count=0;const records=[];
for(let i=0;i<5;i++)for(let n=0;n<100;n++){
 const row={seed:'G165-'+n.toString(16).toUpperCase().padStart(12,'0')+'-01',rarity_name:names[i],registry_id:'test',created_at:'2026-09-09T00:00:00Z'};
 const c=JSON.parse(ctx.nativeReconstruct(JSON.stringify(row)));assert.equal(c.rarity.name,names[i]);assert.equal(c.rarity.displayStars,i+3);assert.equal(c.hiddenRace,false);assert.equal(c.hiddenClass,false);assert.ok(!c.lore.includes('undefined'));
 const race=spec.races.find(r=>r.name.replace('Demi God','Demi-God')===c.baseRace);assert.ok(race.allowed_tiers.includes(spec.tiers[i].id));
 for(const rarity of [c.weaponRarity,...Object.values(c.equipment).map(e=>e.rarity)])assert.ok(names.includes(rarity.name));
 assert.equal(c.rulesVersion,2);assert.deepEqual(JSON.parse(ctx.nativeReconstruct(JSON.stringify(row))),c);count++;
 if(n<5)records.push({row,character:c});
}
fs.writeFileSync(path.join(root,'app/src/test/resources/v2-fixtures.json'),JSON.stringify(records));
console.log(`PASS: ${fixtures.length} unchanged Legacy fixtures/prompts; ${count} V2 reconstructions, race eligibility and equipment tiers.`);
