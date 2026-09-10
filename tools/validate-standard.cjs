const assert = require('node:assert/strict');
const standard = require('../standards/character-standard-v2.json');
assert.equal(standard.tiers.length, 5);
assert.equal(standard.races.length, 42);
assert.ok(Math.abs(standard.tiers.reduce((s,t)=>s+t.base_probability,0)-1)<1e-12);
assert.equal(new Set(standard.races.map(r=>r.id)).size,42);
for(const t of standard.tiers){
 assert.equal(standard.races.filter(r=>r.allowed_tiers.includes(t.id)).length,t.race_count);
}
for(const race of standard.races){
 assert.ok(race.allowed_tiers.length>0);
 assert.ok(race.allowed_tiers.every(id=>standard.tiers.some(t=>t.id===id)));
}
assert.deepEqual(standard.races.find(r=>r.id==='human').allowed_tiers,['common','rare','sr']);
console.log('PASS: 5 tiers, 42 races, 100% base probability, valid race eligibility.');
