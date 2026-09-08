function GenesisSet(a){this.has=function(v){return a.indexOf(v)>=0;};}
const DATA={
  races:[["Human",20],["Elf",6.7],["Orc",5.7],["Dwarf",5.2],["Beastkin",4.8],["Slime",4],["Pale Orc",3.5],["Reptilian",3.5],["Dark Elf",3],["Minotaur",3],["Centaur",3],["Leonin",3],["Imp",2.5],["Shadow",2.5],["Harpy",2.5],["Merfolk",2.5],["Fairy",2.2],["Spiritborn",2.2],["Ghoul",2.2],["Ghost",2.2],["Undead",2.2],["Dragonkin",2],["Vampire",1.8],["Ancient Egyptian",1.8],["Fallen Angel",1.5],["Lich",1.2],["Asgardian",1.2],["Celestial",1],["Voidborn",0.8],["Demon",0.8],["Angel",0.6],["Archangel",0.4],["Demi-God",0.3],["God",0.2],["Targaryen",0],["Dryad",1.8],["Golem",1.6],["Kitsune",1.2],["Krakenborn",1.0],["Djinn",0.9],["Oni",0.8],["Phoenixborn",0.4]],
  genders:["Male","Female"],
  origins:["Kingdom of Elarion","Abyssal Dominion","Celestial Sanctum","Ashen Wastes","Emerald Wilds","Frozen North","Obsidian Empire","Moonlit Archipelago","Sunspire Desert","Forgotten Underworld","Draconic Highlands","City of Aether","Crimson Frontier","The Eternal Library","Ruins of Valhalla","The Void Beyond","Labyrinth of Horns","Forsaken Catacombs","Whispering Moor","Royal Beast Plains","Sunken Tide Kingdom","Foxfire Vale","Verdant Heartwood","Iron Genesis Foundry","Brass Djinn Sultanate","Crimson Oni Provinces","Phoenix Cradle","Leviathan Trench"],
  classes:["Knight","Paladin","Mage","Ranger","Assassin","Berserker","Priest","Necromancer","Samurai","Monk","Warlock","Druid","Spellblade","Gunslinger","Summoner","Dragon Knight","Shadow Knight","Battle Sage","Arcane Duelist","Soul Reaper","Chronomancer","Void Walker","Holy Executioner","Demon Hunter"],
  subclasses:["Vanguard","Runeblade","Starcaller","Soulbound","Blightweaver","Stormchaser","Warden","Oracle","Sentinel","Nightstalker","Flamebearer","Frostborn","Templar","Wildheart","Abysswalker","Gravekeeper","Skydancer","Moonreaper"],
  factions:["Order of the Dawn","Ashen Covenant","Void Tribunal","Emerald Circle","Crimson Legion","Celestial Choir","Blackthorn Syndicate","Dragonspire Guard","Moonveil Court","Eternal Archive","Silver Oath","Abyss Heralds","Stormfront Vanguard","Nine-Tail Court","Verdant Choir","Ironbound Assembly","Brass Covenant","Crimson Oni Clan","Emberwing Order","Deepwake Legion"],
  affinities:["Solar","Lunar","Storm","Infernal","Oceanic","Terrestrial","Arcane","Blood","Astral","Void","Sacred","Verdant","Temporal"],
  abilities:["Soul Devourer","Heavenbreaker","Infinite Arsenal","Blood Dominion","Time Fracture","Void Step","Dragon Roar","Astral Barrage","Shadow Clone","Phoenix Rebirth","World Tree Blessing","Death Mark","Reality Slash","Celestial Judgment","Gravity Collapse","Storm Crown","Frost Prison","Sunfire Nova","Moonlit Mirage","Arcane Overdrive","Spirit Chain","Demonic Ascension","Sacred Sanctuary","Chaos Pulse","Starfall","Foxfire Mirage","Verdant Rebirth","Stoneheart Bastion","Wishbound Seal","Oni Warcry","Phoenix Ascension","Leviathan Surge"],
  ultimates:["Abyssal Cataclysm","Heaven's Final Verdict","Chrono Singularity","Wrath of the World Tree","Crimson Eclipse","Meteoric Dominion","Void Genesis","Dragon Emperor's Roar","Soul Annihilation","Celestial Collapse","Primordial Rift","Storm of Oblivion","Nine-Tail Eclipse","Worldroot Dominion","Colossus Protocol","Sultan of the Burning Sky","Crimson Oni Cataclysm","Eternal Phoenix Rebirth","Leviathan Abyss"],
  passives:["Mana Overdrive","Battle Trance","Regal Presence","Unyielding Resolve","Arcane Reservoir","Predator's Grace","Blessed Armor","Cursed Pulse","Shadow Veil","Dragonblood Resonance","Immortal Recovery","Sixth Sense","Astral Instinct","Void Resistance","Fox Spirit Instinct","Worldroot Communion","Living Stone Core","Wishbound Soul","Oni Blood Fury","Ashen Rebirth","Abyssal Pressure"],
  powers:["Light","Darkness","Fire","Water","Wind","Earth","Lightning","Ice","Nature","Arcane","Holy","Demonic","Void","Blood","Soul","Astral","Chaos","Gravity","Time","Dragon"],
  magics:["Elemental Magic","Ancient Rune Magic","Divine Magic","Forbidden Magic","Blood Magic","Necromancy","Spirit Magic","Dragon Magic","Celestial Magic","Void Magic","Nature Magic","Illusion Magic","Chronomancy","Gravity Magic","Summoning Magic","Curse Magic","Arcane Magic"],
  weapons:[
    "Longsword","Greatsword","Twin Blades","Spear","Halberd","Katana","Scythe","Warhammer","Bow",
    "Arcane Staff","Spellbook","Gauntlets","Dual Pistols","Chain Blade","Dragon Lance","Sacred Relic","Cursed Blade","Crystal Wand",
    "Sunblade Khopesh","Pharaoh Scepter","Relic Spear","Titan Axe","Runic Hammer","Ceremonial Glaive","Obsidian Dagger","Ancient Totem",
    "Void Grimoire","Astral Orb","Soul Lantern","Elemental Tome","Celestial Staff","Chrono Blade","Arcane Chakram","Rune Cannon","Hex Sigil",
    "Magitek Rifle","Hextech Revolver","Combat Shotgun","Twin SMGs","Rail Lance","Energy Saber","Tactical Crossbow","Pulse Cannon","Modern Battle Staff","Foxfire Fan","Worldroot Staff","Runic Golem Fist","Djinn Lampblade","Oni Kanabo","Phoenix Spear","Leviathan Trident"
  ],
  traits:["Six-Winged Awakening","Dragon Blood","Immortal Core","Mana Overdrive","Second Soul","Void Heart","Sacred Mark","Demonic Eye","Phoenix Crest","Astral Body","Moon Blessing","Cursed Bloodline","Runic Skin","Time Sense","Predator Instinct","World Tree Pact","Unbreakable Will","Nine-Tail Blessing","Worldroot Heart","Living Core","Wishbound Sigil","Oni Crest","Eternal Ember","Leviathan Blood"],
  personalities:["Calm","Brave","Ruthless","Cheerful","Stoic","Curious","Proud","Kind","Mysterious","Strategic","Reckless","Noble","Cold","Playful"],
  alignments:["Lawful Good","Neutral Good","Chaotic Good","Lawful Neutral","True Neutral","Chaotic Neutral","Lawful Evil","Neutral Evil","Chaotic Evil"]
};
const RACE_FAMILIES={
  Human:"Mortal",Dwarf:"Mortal",Orc:"Mortal","Pale Orc":"Mortal",
  Elf:"Fae","Dark Elf":"Fae",Fairy:"Fae",Dryad:"Fae",Kitsune:"Fae",
  Beastkin:"Beast",Minotaur:"Beast",Centaur:"Beast",Leonin:"Beast",Harpy:"Beast",Merfolk:"Beast",Reptilian:"Beast",Krakenborn:"Beast",
  Ghoul:"Undead",Ghost:"Undead",Undead:"Undead",Lich:"Undead",Vampire:"Undead",
  Angel:"Celestial",Archangel:"Celestial","Fallen Angel":"Celestial",Celestial:"Celestial",
  Imp:"Infernal",Demon:"Infernal",Oni:"Infernal",
  God:"Divine","Demi-God":"Divine",
  Dragonkin:"Draconic",
  Shadow:"Eldritch",Voidborn:"Eldritch",
  Asgardian:"Ancient","Ancient Egyptian":"Ancient",
  Slime:"Elemental",Djinn:"Elemental",Phoenixborn:"Elemental",
  Spiritborn:"Spirit",
  Golem:"Construct",
  Targaryen:"Special Bloodline"
};
const V155_NEW_RACES=new GenesisSet(["Dryad","Golem","Kitsune","Krakenborn","Djinn","Oni","Phoenixborn"]);
const V155_NEW_RACE_MIN_STARS={Dryad:3,Golem:3,Kitsune:5,Krakenborn:4,Djinn:6,Oni:5,Phoenixborn:7};
const RARITIES=[
  {name:"Common",stars:1,w:30,color:"#b8b0a0"},
  {name:"Uncommon",stars:2,w:22,color:"#71b77e"},
  {name:"Rare",stars:3,w:18,color:"#70aee2"},
  {name:"Special Rare",stars:4,w:12,color:"#55c6d8"},
  {name:"Super Rare",stars:5,w:8,color:"#7f8ee8"},
  {name:"Super Special Rare",stars:6,w:5,color:"#a86fda"},
  {name:"Epic",stars:7,w:3,color:"#c55bcf"},
  {name:"Legendary",stars:8,w:1.5,color:"#e0b45c"},
  {name:"Mythical",stars:9,w:0.4,color:"#e4769d"},
  {name:"Primordial",stars:10,w:0.1,color:"#73e7ed"}
];
const WEAPON_RARITIES=[
  {name:"Common",stars:1,w:34,color:"#b8b0a0"},
  {name:"Uncommon",stars:2,w:24,color:"#71b77e"},
  {name:"Rare",stars:3,w:16,color:"#70aee2"},
  {name:"Special Rare",stars:4,w:10,color:"#55c6d8"},
  {name:"Super Rare",stars:5,w:7,color:"#7f8ee8"},
  {name:"Super Special Rare",stars:6,w:4,color:"#a86fda"},
  {name:"Epic",stars:7,w:2.5,color:"#c55bcf"},
  {name:"Legendary",stars:8,w:1.5,color:"#e0b45c"},
  {name:"Mythical",stars:9,w:0.8,color:"#e4769d"},
  {name:"Primordial",stars:10,w:0.2,color:"#73e7ed"}
];
const WEAPON_GROUPS={
  "Ancient Weapon":["Sunblade Khopesh","Pharaoh Scepter","Relic Spear","Titan Axe","Runic Hammer","Ceremonial Glaive","Obsidian Dagger","Ancient Totem"],
  "Magic Weapon":["Arcane Staff","Spellbook","Dragon Lance","Sacred Relic","Cursed Blade","Crystal Wand","Void Grimoire","Astral Orb","Soul Lantern","Elemental Tome","Celestial Staff","Chrono Blade","Arcane Chakram","Rune Cannon","Hex Sigil"],
  "Modern Weapon":["Dual Pistols","Magitek Rifle","Hextech Revolver","Combat Shotgun","Twin SMGs","Rail Lance","Energy Saber","Tactical Crossbow","Pulse Cannon","Modern Battle Staff"]
};
const EQUIPMENT_RARITIES=[
  {name:"Common",stars:1,w:36,color:"#b8b0a0"},
  {name:"Uncommon",stars:2,w:25,color:"#71b77e"},
  {name:"Rare",stars:3,w:16,color:"#70aee2"},
  {name:"Special Rare",stars:4,w:10,color:"#55c6d8"},
  {name:"Super Rare",stars:5,w:6,color:"#7f8ee8"},
  {name:"Super Special Rare",stars:6,w:3.5,color:"#a86fda"},
  {name:"Epic",stars:7,w:1.8,color:"#c55bcf"},
  {name:"Legendary",stars:8,w:1,color:"#e0b45c"},
  {name:"Mythical",stars:9,w:0.6,color:"#e4769d"},
  {name:"Primordial",stars:10,w:0.1,color:"#73e7ed"}
];
const EQUIPMENT_POOLS={
  Armor:[
    "Iron Vanguard Plate","Runebound Armor","Dragonbone Mail","Voidweave Robe","Seraphic Plate",
    "Crimson Warlord Armor","Moonveil Garment","Titanhide Cuirass","Aether Knight Coat","Pharaoh Warplate",
    "Living Slime Armor","Astral Guardian Mail","Shadowstalker Mantle","Stormforged Plate"
  ],
  Accessory:[
    "Moonstone Ring","Phoenix Pendant","Eye of the Oracle","Dragonfang Necklace","Voidglass Ring",
    "Golden Scarab Charm","Bifrost Bracelet","Blood Ruby Brooch","World Tree Amulet","Chrono Pocketwatch",
    "Lionheart Talisman","Arcane Earring","Soulbound Rosary","Celestial Signet"
  ],
  Relic:[
    "Fragment of the First Heaven","Ancient Dragon Heart","Pharaoh's Eternal Seal","Ashes of the Phoenix",
    "Frozen Tear of Valhalla","Black Sun Fragment","Saint's Last Prayer","World Tree Seedling",
    "Eye of Eternity","Bone Crown Shard","Abyssal Compass","Tablet of Forgotten Names"
  ],
  Artifact:[
    "World Seed","Chrono Heart","Crown of the Abyss","Orb of Infinite Stars","Genesis Crystal",
    "Mirror of Lost Souls","Eclipse Engine","Divine Law Tablet","Primordial Ember","Void Keystone",
    "Astral Throne Fragment","Book of Unwritten Fate"
  ]
};
const EQUIPMENT_EFFECTS={
  Armor:["Damage Guard","Elemental Resistance","Immortal Ward","Fortified Core","Magic Barrier","Battle Regeneration"],
  Accessory:["Critical Fortune","Mana Recovery","Speed Blessing","Lucky Star","Soul Focus","Precision Aura"],
  Relic:["Ancient Resonance","Divine Protection","Bloodline Awakening","Time Echo","Spirit Amplification","Forbidden Knowledge"],
  Artifact:["Reality Anchor","World Law Override","Primordial Surge","Astral Dominion","Void Authority","Fate Distortion"]
};
const ASCENSION_STAGES=[
  {name:"Base",levelReq:1,essenceCost:0,cpMult:1.00,statMult:1.00},
  {name:"Awakened",levelReq:25,essenceCost:250,cpMult:1.10,statMult:1.05},
  {name:"Ascended",levelReq:50,essenceCost:600,cpMult:1.24,statMult:1.12},
  {name:"Transcendent",levelReq:80,essenceCost:1200,cpMult:1.45,statMult:1.22}
];
const TARGARYEN_ELIGIBLE_CHANCE=0.7;
const DAILY_MISSION_POOL=[
  {id:"summon5",metric:"summons",target:5,title:"Answer the Call",desc:"Perform 5 character summons.",reward:{gp:10,xp:15},tag:"Summon"},
  {id:"summon10",metric:"summons",target:10,title:"Ten Threads of Fate",desc:"Perform 10 character summons.",reward:{gp:15,essence:20,xp:20},tag:"Summon"},
  {id:"gp50",metric:"gpEarned",target:50,title:"Gather Gacha Energy",desc:"Earn 50 GP from summon results.",reward:{essence:35,xp:15},tag:"Economy"},
  {id:"rare3",metric:"rarePlus",target:3,title:"Rare Resonance",desc:"Summon 3 Rare-or-higher characters.",reward:{essence:30,xp:15},tag:"Rarity"},
  {id:"super1",metric:"superRarePlus",target:1,title:"Beyond the Ordinary",desc:"Summon 1 Super Rare-or-higher character.",reward:{essence:40,xp:20},tag:"Rarity"},
  {id:"discovery1",metric:"newDiscovery",target:1,title:"Expand the Codex",desc:"Make 1 new Codex discovery from a summon.",reward:{gp:15,xp:20},tag:"Discovery"},
  {id:"save2",metric:"saveCharacters",target:2,title:"Preserve Their Names",desc:"Save 2 newly obtained characters to Collection.",reward:{essence:30,xp:15},tag:"Collection"},
  {id:"progress1",metric:"characterProgress",target:1,title:"Strengthen a Hero",desc:"Train a character or advance an evolution stage.",reward:{essence:20,xp:20},tag:"Progression"},
  {id:"gear1",metric:"upgradeGear",target:1,title:"Temper the Arsenal",desc:"Upgrade a weapon or equipment item once.",reward:{essence:25,xp:20},tag:"Upgrade"},
  {id:"spend100",metric:"essenceSpent",target:100,title:"Invest in Power",desc:"Spend 100 Essence on character progression or upgrades.",reward:{gp:10,xp:20},tag:"Economy"}
];
const LOGIN_REWARDS=[
  {day:1,gp:5,label:"5 GP"},
  {day:2,essence:25,label:"25 Essence"},
  {day:3,gp:10,label:"10 GP"},
  {day:4,essence:50,label:"50 Essence"},
  {day:5,gp:15,label:"15 GP"},
  {day:6,essence:100,label:"100 Essence"},
  {day:7,gp:25,essence:150,label:"25 GP + 150 Essence"}
];
const ACHIEVEMENTS=[
  // SUMMON
  {id:"first_legendary",icon:"★",name:"A Living Legend",desc:"Summon a Legendary character.",category:"Summon",tier:"Silver",ap:10,reward:{essence:30}},
  {id:"first_mythical",icon:"✦",name:"Beyond Legend",desc:"Summon a Mythical character.",category:"Summon",tier:"Gold",ap:20,reward:{gp:10,essence:50}},
  {id:"first_primordial",icon:"✹",name:"Before History",desc:"Summon a Primordial character.",category:"Summon",tier:"Mythic",ap:50,reward:{gp:25,essence:100}},
  {id:"first_10x",icon:"▦",name:"Tenfold Fate",desc:"Perform your first 10x Summon.",category:"Summon",tier:"Bronze",ap:5,reward:{essence:20}},
  {id:"summons_100",icon:"∞",name:"Hundred Destinies",desc:"Reach 100 total summons.",category:"Summon",tier:"Silver",ap:10,reward:{gp:10,essence:40}},
  {id:"summons_500",icon:"∞",name:"Five Hundred Destinies",desc:"Reach 500 total summons.",category:"Summon",tier:"Gold",ap:20,reward:{gp:20,essence:75}},
  {id:"summons_1000",icon:"∞",name:"Thousandfold Fate",desc:"Reach 1,000 total summons.",category:"Summon",tier:"Mythic",ap:50,reward:{gp:40,essence:150}},
  {id:"legendary_10",icon:"★",name:"Legends Gather",desc:"Summon 10 Legendary-or-higher characters.",category:"Summon",tier:"Gold",ap:20,reward:{essence:75}},
  {id:"mythical_5",icon:"✦",name:"Myths Walk Among Us",desc:"Summon 5 Mythical-or-higher characters.",category:"Summon",tier:"Mythic",ap:50,reward:{gp:25,essence:100}},

  // CODEX
  {id:"race_10",icon:"◈",name:"Racial Scholar",desc:"Discover 10 base races.",category:"Codex",tier:"Bronze",ap:5,reward:{essence:20}},
  {id:"race_25",icon:"◈",name:"Keeper of Bloodlines",desc:"Discover 25 base races.",category:"Codex",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"all_races",icon:"◉",name:"Genesis Bestiary",desc:"Discover all 42 base races.",category:"Codex",tier:"Mythic",ap:50,reward:{gp:30,essence:150}},
  {id:"family_mortal",icon:"◇",name:"Chronicle of Mortals",desc:"Discover every Mortal race.",category:"Codex",tier:"Silver",ap:10,reward:{essence:30}},
  {id:"family_fae",icon:"◇",name:"Chronicle of the Fae",desc:"Discover every Fae race.",category:"Codex",tier:"Silver",ap:10,reward:{essence:30}},
  {id:"family_undead",icon:"◇",name:"Chronicle of the Deathless",desc:"Discover every Undead race.",category:"Codex",tier:"Silver",ap:10,reward:{essence:30}},
  {id:"all_families",icon:"✺",name:"Master of Bloodlines",desc:"Discover all Race Families.",category:"Codex",tier:"Gold",ap:20,reward:{gp:15,essence:60}},
  {id:"all_rarities",icon:"✺",name:"Master of Rarity",desc:"Discover all 10 character rarities.",category:"Codex",tier:"Gold",ap:20,reward:{gp:15,essence:60}},
  {id:"hidden_form",icon:"◇",name:"Secret Awakening",desc:"Discover a Hidden Race or Hidden Class.",category:"Codex",tier:"Silver",ap:10,reward:{essence:35}},

  // COLLECTION
  {id:"collector_10",icon:"▣",name:"Growing Archive",desc:"Save 10 characters to your Collection.",category:"Collection",tier:"Bronze",ap:5,reward:{essence:20}},
  {id:"collector_25",icon:"▦",name:"Grand Collector",desc:"Save 25 characters to your Collection.",category:"Collection",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"collector_100",icon:"▦",name:"Vault of Heroes",desc:"Save 100 characters to your Collection.",category:"Collection",tier:"Gold",ap:20,reward:{gp:20,essence:75}},
  {id:"collection_legendary_10",icon:"★",name:"Hall of Legends",desc:"Own 10 Legendary-or-higher characters.",category:"Collection",tier:"Gold",ap:20,reward:{essence:75}},
  {id:"collection_mythical_5",icon:"✦",name:"Mythic Archive",desc:"Own 5 Mythical-or-higher characters.",category:"Collection",tier:"Mythic",ap:50,reward:{gp:25,essence:100}},
  {id:"favorites_10",icon:"♥",name:"Chosen Ten",desc:"Mark 10 Collection characters as Favorites.",category:"Collection",tier:"Silver",ap:10,reward:{essence:35}},

  // PROGRESSION
  {id:"summoner_25",icon:"♜",name:"Veteran Summoner",desc:"Reach Summoner Level 25.",category:"Progression",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"summoner_50",icon:"♜",name:"Master Summoner",desc:"Reach Summoner Level 50.",category:"Progression",tier:"Gold",ap:20,reward:{gp:15,essence:75}},
  {id:"first_duplicate",icon:"♻",name:"Echo of Fate",desc:"Obtain a repeated base Race + Class combination.",category:"Progression",tier:"Bronze",ap:5,reward:{essence:20}},
  {id:"first_awakened",icon:"✧",name:"Awakened Potential",desc:"Awaken a collected character.",category:"Progression",tier:"Bronze",ap:5,reward:{essence:25}},
  {id:"first_ascended",icon:"✧",name:"Higher Form",desc:"Reach Ascended stage with a character.",category:"Progression",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"first_transcendent",icon:"✵",name:"Beyond the Mortal Frame",desc:"Reach Transcendent stage.",category:"Progression",tier:"Gold",ap:20,reward:{gp:15,essence:75}},
  {id:"character_level_50",icon:"50",name:"Seasoned Hero",desc:"Raise a character to Level 50.",category:"Progression",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"character_level_100",icon:"100",name:"Perfected Hero",desc:"Raise a character to Level 100.",category:"Progression",tier:"Gold",ap:20,reward:{gp:15,essence:75}},
  {id:"weapon_plus_10",icon:"⚔",name:"Masterwork Weapon",desc:"Upgrade a weapon to +10.",category:"Progression",tier:"Gold",ap:20,reward:{essence:75}},
  {id:"all_gear_plus_10",icon:"◆",name:"Perfect Loadout",desc:"Raise Weapon, Armor, Accessory, Relic, and Artifact to +10 on one character.",category:"Progression",tier:"Mythic",ap:50,reward:{gp:30,essence:150}},
  {id:"essence_1000",icon:"◆",name:"Essence Hoarder",desc:"Hold at least 1,000 Essence.",category:"Progression",tier:"Silver",ap:10,reward:{essence:25}},
  {id:"power_12000",icon:"⚡",name:"Powerhouse",desc:"Create a character with 12,000+ Combat Power.",category:"Progression",tier:"Silver",ap:10,reward:{essence:40}},

  // DAILY
  {id:"daily_10",icon:"☷",name:"Daily Routine",desc:"Claim rewards from 10 Daily Missions.",category:"Daily",tier:"Bronze",ap:5,reward:{essence:25}},
  {id:"daily_50",icon:"☷",name:"Steady Destiny",desc:"Claim rewards from 50 Daily Missions.",category:"Daily",tier:"Silver",ap:10,reward:{gp:10,essence:50}},
  {id:"daily_100",icon:"☷",name:"Keeper of the Cycle",desc:"Claim rewards from 100 Daily Missions.",category:"Daily",tier:"Gold",ap:20,reward:{gp:20,essence:80}},
  {id:"perfect_daily",icon:"✓",name:"Perfect Day",desc:"Complete and claim all 6 Daily Missions in one day.",category:"Daily",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"login_7",icon:"☀",name:"Seven Dawns",desc:"Complete a full 7-day Login Reward cycle.",category:"Daily",tier:"Silver",ap:10,reward:{gp:10,essence:40}},
  {id:"login_30",icon:"☀",name:"Thirty Dawns",desc:"Claim 30 total Login Rewards.",category:"Daily",tier:"Gold",ap:20,reward:{gp:20,essence:80}},

  // SPECIAL
  {id:"summon_god",icon:"☀",name:"Audience with Divinity",desc:"Summon a God.",category:"Special",tier:"Gold",ap:20,reward:{gp:15,essence:60}},
  {id:"summon_archangel",icon:"☼",name:"Heaven's Messenger",desc:"Summon an Archangel.",category:"Special",tier:"Silver",ap:10,reward:{essence:40}},
  {id:"primordial_human",icon:"♛",name:"Impossible Mortal",desc:"Summon a Human with Primordial rarity.",category:"Special",tier:"Mythic",ap:50,reward:{gp:30,essence:150}},
  {id:"primordial_weapon",icon:"⚔",name:"Weapon of Origin",desc:"Obtain a Primordial weapon.",category:"Special",tier:"Mythic",ap:50,reward:{gp:25,essence:120}},
  {id:"primordial_equipment",icon:"◆",name:"Relic Beyond Time",desc:"Obtain any Primordial equipment piece.",category:"Special",tier:"Mythic",ap:50,reward:{gp:25,essence:120}}
];
let rng=Math.random;const rand=a=>a[Math.floor(rng()*a.length)];const chance=p=>rng()<p;function makeSeed(){throw new Error("Server seed required");}
function raceFamily(race){return RACE_FAMILIES[race]||"Unknown"}
function hashSeed(str){
  let h=2166136261>>>0;
  for(const ch of String(str)){h^=ch.charCodeAt(0);h=Math.imul(h,16777619)}
  return h>>>0;
}
function mulberry32(a){return function(){let t=a+=0x6D2B79F5;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return((t^t>>>14)>>>0)/4294967296}}
function normalizeSeed(s){return String(s||"").trim().toUpperCase().replace(/[^A-Z0-9_-]/g,"").slice(0,40)}
function characterIdFromSeed(seed){
  const a=hashSeed(seed).toString(36).toUpperCase().padStart(7,"0");
  const b=hashSeed(seed+"|MCG").toString(36).toUpperCase().padStart(7,"0");
  return `MCG-${a.slice(-4)}-${b.slice(-4)}`;
}
function weighted(list){const s=list.reduce((a,b)=>a+b[1],0);let r=rng()*s;for(const x of list){r-=x[1];if(r<=0)return x[0]}return list[0][0]}
function rarityRoll(){const s=RARITIES.reduce((a,b)=>a+b.w,0);let r=rng()*s;for(const x of RARITIES){r-=x.w;if(r<=0)return {...x}}return {...RARITIES[0]}}
function weaponCategory(name){
  for(const [category,items] of Object.entries(WEAPON_GROUPS)){
    if(items.includes(name))return category;
  }
  return "Traditional Weapon";
}
function weightedWith(customRng,list){
  const total=list.reduce((a,b)=>a+b.w,0);
  let r=customRng()*total;
  for(const x of list){r-=x.w;if(r<=0)return {...x}}
  return {...list[0]}
}
function weaponEffectPool(category){
  const pools={
    "Traditional Weapon":[
      "Armor Break","Duelist's Edge","Critical Momentum","Guardian's Resolve","Bleeding Strike","Counter Mastery"
    ],
    "Ancient Weapon":[
      "Forgotten Rune","Titan Resonance","Pharaoh's Curse","Relic Awakening","Ancestral Echo","Seal of the First Age"
    ],
    "Magic Weapon":[
      "Mana Surge","Void Pierce","Soul Bind","Chrono Echo","Celestial Burst","Arcane Overload"
    ],
    "Modern Weapon":[
      "Overcharge Burst","Rail Impact","Smart Targeting","Arcane Magazine","Pulse Accelerator","Tactical Lock-On"
    ]
  };
  return pools[category]||pools["Traditional Weapon"];
}
function generateWeaponProfile(weapon,seed){
  const wrng=mulberry32(hashSeed(seed+"|WEAPON"));
  const rarity=weightedWith(wrng,WEAPON_RARITIES);
  const category=weaponCategory(weapon);
  const base={1:120,2:180,3:260,4:360,5:480,6:620,7:800,8:1050,9:1400,10:1900}[rarity.stars];
  const spread={1:70,2:90,3:120,4:150,5:190,6:240,7:300,8:380,9:480,10:650}[rarity.stars];
  const categoryBonus={"Traditional Weapon":30,"Ancient Weapon":85,"Magic Weapon":75,"Modern Weapon":65}[category]||30;
  const power=Math.round(base+wrng()*spread+categoryBonus);
  const effects=weaponEffectPool(category);
  const effect=effects[Math.floor(wrng()*effects.length)];
  return {
    weaponCategory:category,
    weaponRarity:rarity,
    weaponRarityChance:rarity.w,
    weaponPower:power,
    weaponEffect:effect
  };
}
function generateEquipmentPiece(slot,seed){
  const erng=mulberry32(hashSeed(seed+"|EQUIP|"+slot.toUpperCase()));
  const rarity=weightedWith(erng,EQUIPMENT_RARITIES);
  const names=EQUIPMENT_POOLS[slot];
  const effects=EQUIPMENT_EFFECTS[slot];
  const name=names[Math.floor(erng()*names.length)];
  const effect=effects[Math.floor(erng()*effects.length)];
  const base={1:45,2:70,3:105,4:150,5:210,6:285,7:380,8:510,9:700,10:980}[rarity.stars];
  const spread={1:30,2:40,3:55,4:75,5:100,6:130,7:170,8:220,9:300,10:420}[rarity.stars];
  return {
    slot,name,rarity,rarityChance:rarity.w,
    power:Math.round(base+erng()*spread),
    effect
  };
}
function generateEquipmentLoadout(seed){
  return {
    armor:generateEquipmentPiece("Armor",seed),
    accessory:generateEquipmentPiece("Accessory",seed),
    relic:generateEquipmentPiece("Relic",seed),
    artifact:generateEquipmentPiece("Artifact",seed)
  };
}
function equipmentPowerTotal(c){
  return Object.values(c.equipment||{}).reduce((sum,x)=>sum+(Number(x?.power)||0),0);
}
function ensureProgression(c){
  if(!c)return c;
  c.progression={level:1,xp:0,stage:0,duplicates:0,...(c.progression||{})};
  c.weaponUpgrade=Math.max(0,Math.min(10,Number(c.weaponUpgrade)||0));
  if(c.equipment){
    for(const eq of Object.values(c.equipment)){
      if(eq)eq.upgrade=Math.max(0,Math.min(10,Number(eq.upgrade)||0));
    }
  }
  return c;
}
function characterXpNeeded(level){
  if(level>=100)return 0;
  return 70+level*18+Math.floor(level*level*0.6);
}
function trainingEssenceCost(level){
  return Math.max(12,Math.round(10+level*2.4));
}
function stageInfo(c){return ASCENSION_STAGES[Math.max(0,Math.min(3,c?.progression?.stage||0))]}
function nextStageInfo(c){return ASCENSION_STAGES[(c?.progression?.stage||0)+1]||null}
function progressionLevelMultiplier(c){
  return 1+Math.max(0,(c?.progression?.level||1)-1)*0.006;
}
function weaponUpgradeMultiplier(c){return 1+(Number(c?.weaponUpgrade)||0)*0.065}
function equipmentUpgradeMultiplier(eq){return 1+(Number(eq?.upgrade)||0)*0.055}
function effectiveStats(c){
  ensureProgression(c);
  const mult=stageInfo(c).statMult*(1+Math.max(0,c.progression.level-1)*0.0035);
  const out={};
  for(const [k,v] of Object.entries(c.stats||{}))out[k]=Math.round(v*mult);
  return out;
}
function upgradedWeaponPower(c){
  return Math.round((Number(c.weaponPower)||0)*weaponUpgradeMultiplier(c));
}
function upgradedEquipmentPower(eq){
  return Math.round((Number(eq?.power)||0)*equipmentUpgradeMultiplier(eq));
}
function equipmentPowerTotalUpgraded(c){
  return Object.values(c.equipment||{}).reduce((sum,eq)=>sum+upgradedEquipmentPower(eq),0);
}
function weaponUpgradeCost(level){
  if(level>=10)return 0;
  return Math.round(45+level*35+level*level*4);
}
function equipmentUpgradeCost(eq){
  const level=Number(eq?.upgrade)||0;
  if(level>=10)return 0;
  const rarityFactor=1+(Number(eq?.rarity?.stars||1)-1)*0.08;
  return Math.round((30+level*26+level*level*3)*rarityFactor);
}
function overallRatingFromPower(cp){
  if(cp>=15000)return "SSS";
  if(cp>=13500)return "SS";
  if(cp>=12000)return "S";
  if(cp>=10500)return "A";
  if(cp>=9000)return "B";
  if(cp>=7600)return "C";
  return "D";
}
function computeCombatPower(c){
  ensureProgression(c);
  const statTotal=Object.values(effectiveStats(c)).reduce((a,b)=>a+(Number(b)||0),0);
  const rarityBonus=(c.rarity?.stars||1)*280;
  const weaponBonus=upgradedWeaponPower(c)*1.4;
  const equipmentBonus=equipmentPowerTotalUpgraded(c)*1.15;
  const raceBonus=Math.min(900,Math.max(0,(20-(Number(c.raceChance)||20))*40));
  const hiddenBonus=(c.hiddenRace?650:0)+(c.hiddenClass?650:0);
  const traitBonus=["Immortal Core","Six-Winged Awakening","Void Heart","Dragon Blood"].includes(c.trait)?260:100;
  const stageMultiplier=stageInfo(c).cpMult;
  return Math.round((statTotal*12+rarityBonus+weaponBonus+equipmentBonus+raceBonus+hiddenBonus+traitBonus)*stageMultiplier);
}
function ensureAdvancedData(c){
  if(!c)return c;
  const legacySeed=c.seed||c.characterId||"LEGACY";
  if(!c.weaponCategory||!c.weaponRarity||!c.weaponPower||!c.weaponEffect){
    Object.assign(c,generateWeaponProfile(c.weapon,legacySeed));
  }
  if(!c.equipment||!c.equipment.armor||!c.equipment.accessory||!c.equipment.relic||!c.equipment.artifact){
    c.equipment=generateEquipmentLoadout(legacySeed);
  }
  ensureProgression(c);
  c.raceCategory=c.raceCategory||raceFamily(c.baseRace||c.race);
  c.combatPower=computeCombatPower(c);
  c.overallRating=overallRatingFromPower(c.combatPower);
  return c;
}
function rarityStarsByName(name){
  return RARITIES.find(r=>r.name===name)?.stars||1;
}
function raceAllowedAtRarity(race,rarityName){
  const stars=rarityStarsByName(rarityName);
  if(race==="God")return ["Mythical","Primordial"].includes(rarityName);
  if(["Demi-God","Archangel","Angel","Demon"].includes(race))return stars>=6;
  if(race==="Targaryen")return stars>=8;
  if(V155_NEW_RACES.has(race))return stars>=(V155_NEW_RACE_MIN_STARS[race]||1);
  return true;
}
function raceBaseWeight(race){
  if(race==="Targaryen")return TARGARYEN_ELIGIBLE_CHANCE;
  const row=DATA.races.find(x=>x[0]===race);
  return row?row[1]:0;
}
function weightedPairWith(customRng,list){
  const total=list.reduce((sum,x)=>sum+x[1],0);
  let r=customRng()*total;
  for(const x of list){r-=x[1];if(r<=0)return x[0]}
  return list[0]?.[0]||"Human";
}
function legacyRacePool(){
  return DATA.races.filter(([race,w])=>w>0&&!V155_NEW_RACES.has(race));
}
function eligibleOriginalRacePool(rarityName){
  return legacyRacePool().filter(([race])=>raceAllowedAtRarity(race,rarityName));
}
function eligibleV155RacePool(rarityName){
  const pool=DATA.races.filter(([race,w])=>w>0&&raceAllowedAtRarity(race,rarityName)).map(x=>[x[0],x[1]]);
  if(raceAllowedAtRarity("Targaryen",rarityName))pool.push(["Targaryen",TARGARYEN_ELIGIBLE_CHANCE]);
  return pool;
}
function raceProbability(race,rarityName=null,seed=null){
  if(!rarityName)return raceBaseWeight(race);
  if(!raceAllowedAtRarity(race,rarityName))return 0;

  if(/^G(?:155|161|163)-/.test(String(seed||""))){
    const pool=eligibleV155RacePool(rarityName);
    const total=pool.reduce((sum,x)=>sum+x[1],0);
    const row=pool.find(x=>x[0]===race);
    return row&&total?row[1]/total*100:0;
  }

  const targaryenAllowed=raceAllowedAtRarity("Targaryen",rarityName);
  if(race==="Targaryen")return targaryenAllowed?TARGARYEN_ELIGIBLE_CHANCE:0;
  if(V155_NEW_RACES.has(race))return 0;

  const pool=eligibleOriginalRacePool(rarityName);
  const total=pool.reduce((sum,x)=>sum+x[1],0);
  const row=pool.find(x=>x[0]===race);
  if(!row||!total)return 0;
  const remaining=targaryenAllowed?(100-TARGARYEN_ELIGIBLE_CHANCE):100;
  return row[1]/total*remaining;
}
function pickRace(rarityName,seed){
  const gateRng=mulberry32(hashSeed(seed+"|RACE_GATE_V155"));

  if(/^G(?:155|161|163)-/.test(String(seed||""))){
    return weightedPairWith(gateRng,eligibleV155RacePool(rarityName));
  }

  const legacyRace=weightedPairWith(rng,legacyRacePool());
  if(raceAllowedAtRarity("Targaryen",rarityName) && gateRng()*100<TARGARYEN_ELIGIBLE_CHANCE)return "Targaryen";
  if(raceAllowedAtRarity(legacyRace,rarityName))return legacyRace;
  return weightedPairWith(gateRng,eligibleOriginalRacePool(rarityName));
}
function pickClass(){return rand(DATA.classes)}
function pickOrigin(){return rand(DATA.origins)}
function seedSubRng(seed,label){return mulberry32(hashSeed(`${seed}|${label}`))}
function pickClassForSeed(seed){
  if(String(seed||"").startsWith("G163-")){
    const r=seedSubRng(seed,"CLASS_V163");
    return DATA.classes[Math.floor(r()*DATA.classes.length)];
  }
  return pickClass();
}
function pickWeaponForSeed(seed){
  if(String(seed||"").startsWith("G163-")){
    const r=seedSubRng(seed,"WEAPON_NAME_V163");
    return DATA.weapons[Math.floor(r()*DATA.weapons.length)];
  }
  return rand(DATA.weapons);
}
function pickTraitForSeed(seed,fallback){
  if(String(seed||"").startsWith("G163-")){
    const r=seedSubRng(seed,"TRAIT_V163");
    return DATA.traits[Math.floor(r()*DATA.traits.length)];
  }
  return fallback;
}
function hiddenEvolutionV163(race,cls,rarity,seed){
  if(!String(seed||"").startsWith("G163-"))return hiddenEvolution(race,cls,rarity);
  const c={Common:0,Uncommon:0,Rare:.003,"Special Rare":.008,"Super Rare":.015,"Super Special Rare":.025,Epic:.05,Legendary:.10,Mythical:.22,Primordial:.45}[rarity.name]||0;
  const hrng=seedSubRng(seed,"HIDDEN_V163");
  if(hrng()>=c)return {race,cls,hiddenRace:false,hiddenClass:false};
  const ev={
    Angel:["High Seraph","Nephilim"],Archangel:["Throneseraph","Heaven's Spear"],Demon:["Archdemon","Infernal Sovereign"],
    Dragonkin:["Primordial Dragon","Dragon Ascendant"],Voidborn:["Eldritch Born","Outer Void Entity"],Celestial:["Godborn","Astral Deity"],
    Vampire:["Blood Progenitor","Crimson Ancestor"],Elf:["High Fae","World Tree Scion"],"Dark Elf":["Abyssal Fae","Night Sovereign"],
    Spiritborn:["Ancient Spirit","Astral Incarnate"],Minotaur:["Labyrinth Lord","Horned Titan"],Imp:["Infernal Trickster","Hellfire Imp King"],
    Shadow:["Night Incarnate","Eclipse Phantom"],Centaur:["Starhoof Champion","Ancient Plains Lord"],Ghoul:["Grave Devourer","Carrion King"],
    Ghost:["Spectral Monarch","Wailing Apparition"],Undead:["Deathless Sovereign","Bone Tyrant"],Lich:["Archlich","Crypt Emperor"],
    Harpy:["Storm Harbinger","Sky Queen"],Merfolk:["Tide Oracle","Abyssal Mariner"],"Pale Orc":["Frostfang Warlord","Bonecrusher King"],
    Leonin:["Sunmane Sovereign","Golden Pride King"],Slime:["Primordial Slime","Abyssal Gel Monarch"],Reptilian:["Scaled Tyrant","Basilisk Descendant"],
    Asgardian:["Odinblood Heir","Bifrost Champion"],"Ancient Egyptian":["Pharaoh Eternal","Anubian Oracle"],God:["Creator Aspect","Divine Origin"],
    "Demi-God":["Ascended Scion","Heaven-Touched Hero"],Targaryen:["Dragonlord Ascendant","Blood of Old Valyria"],
    Dryad:["Elder Dryad","Worldroot Avatar"],Golem:["Colossus Golem","Genesis Construct"],Kitsune:["Nine-Tailed Kitsune","Moonfire Fox Spirit"],
    Krakenborn:["Leviathan Scion","Abyssal Kraken Lord"],Djinn:["Ifrit Sovereign","Wishbound Monarch"],Oni:["Crimson Oni Lord","Thunder Oni"],
    Phoenixborn:["Eternal Phoenix","Solar Rebirth Avatar"]
  };
  let rr=race,cc=cls,hiddenRace=false,hiddenClass=false;
  if(ev[race]&&hrng()<.72){rr=ev[race][Math.floor(hrng()*ev[race].length)];hiddenRace=true}
  const secret=[
    "Reality Breaker","Eternal Vanguard","World Weaver","Seraph Warlord","Divine Arbiter","Abyss Sovereign","Void Monarch",
    "Dragon Emperor","Wyrm Godslayer","Deathlord","Crypt Sovereign","Primal Overlord","Wild King","Grand Arcanist",
    "Sacred Champion","Relic Overlord","Mythic Gunslinger","Ancient Weapon Master"
  ];
  const secretRoll=hrng()<.64;
  if(secretRoll||rarity.name==="Primordial"){cc=secret[Math.floor(hrng()*secret.length)];hiddenClass=true}
  return {race:rr,cls:cc,hiddenRace,hiddenClass};
}
function ageForRace(r){
  const m={"Human":[18,55],"Elf":[40,420],"Dark Elf":[50,500],"Dwarf":[35,240],"Beastkin":[18,100],"Orc":[18,95],"Pale Orc":[20,120],"Demon":[80,900],
  "Angel":[100,1200],"Archangel":[300,6000],"Dragonkin":[30,650],"Vampire":[70,700],"Fairy":[20,600],"Spiritborn":[40,900],"Fallen Angel":[100,1400],
  "Celestial":[200,3000],"Voidborn":[500,9000],"Minotaur":[22,180],"Imp":[18,220],"Shadow":[50,1200],"Centaur":[20,160],"Ghoul":[30,400],"Ghost":[40,2000],
  "Undead":[35,1500],"Lich":[250,5000],"Harpy":[18,180],"Merfolk":[20,240],"Leonin":[20,130],"Slime":[1,350],"Reptilian":[18,220],
  "Asgardian":[150,5000],"Ancient Egyptian":[18,500],"God":[1000,12000],"Demi-God":[80,3000],"Targaryen":[16,120],"Dryad":[30,900],"Golem":[1,3000],"Kitsune":[25,1200],"Krakenborn":[30,800],"Djinn":[100,4000],"Oni":[25,700],"Phoenixborn":[50,5000]};
  const [a,b]=m[r]||[18,100];return Math.floor(a+rng()*(b-a+1))
}
function synergy(race,cls,rarity){
  let power=rand(DATA.powers),magic=rand(DATA.magics),ability=rand(DATA.abilities),trait=rand(DATA.traits),title=null;
  const p={
    Angel:{p:["Light","Holy","Astral"],m:["Divine Magic","Celestial Magic"],a:["Celestial Judgment","Sacred Sanctuary","Starfall"]},
    Archangel:{p:["Light","Holy","Astral","Time"],m:["Divine Magic","Celestial Magic","Chronomancy"],a:["Celestial Judgment","Sacred Sanctuary","Starfall"]},
    Demon:{p:["Demonic","Fire","Darkness","Chaos"],m:["Forbidden Magic","Curse Magic","Blood Magic"],a:["Demonic Ascension","Soul Devourer","Chaos Pulse"]},
    Dragonkin:{p:["Dragon","Fire","Lightning"],m:["Dragon Magic","Elemental Magic"],a:["Dragon Roar","Sunfire Nova","Storm Crown"]},
    Vampire:{p:["Blood","Darkness","Soul"],m:["Blood Magic","Curse Magic","Necromancy"],a:["Blood Dominion","Soul Devourer","Death Mark"]},
    Voidborn:{p:["Void","Chaos","Gravity"],m:["Void Magic","Gravity Magic","Forbidden Magic"],a:["Reality Slash","Gravity Collapse","Void Step"]},
    Minotaur:{p:["Earth","Blood","Chaos"],m:["Ancient Rune Magic","Blood Magic"],a:["Gravity Collapse","Chaos Pulse","World Tree Blessing"]},
    Imp:{p:["Fire","Chaos","Demonic"],m:["Curse Magic","Forbidden Magic"],a:["Chaos Pulse","Shadow Clone","Demonic Ascension"]},
    Shadow:{p:["Darkness","Void","Soul"],m:["Illusion Magic","Void Magic","Curse Magic"],a:["Shadow Clone","Void Step","Death Mark"]},
    Centaur:{p:["Nature","Wind","Earth"],m:["Nature Magic","Spirit Magic"],a:["Moonlit Mirage","World Tree Blessing","Astral Barrage"]},
    Ghoul:{p:["Blood","Soul","Darkness"],m:["Necromancy","Curse Magic"],a:["Soul Devourer","Death Mark","Blood Dominion"]},
    Ghost:{p:["Soul","Astral","Darkness"],m:["Spirit Magic","Illusion Magic","Necromancy"],a:["Spirit Chain","Moonlit Mirage","Soul Devourer"]},
    Undead:{p:["Soul","Darkness","Blood"],m:["Necromancy","Blood Magic"],a:["Soul Devourer","Blood Dominion","Death Mark"]},
    Lich:{p:["Soul","Void","Time"],m:["Necromancy","Void Magic","Chronomancy"],a:["Time Fracture","Soul Devourer","Gravity Collapse"]},
    Harpy:{p:["Wind","Lightning","Nature"],m:["Elemental Magic","Nature Magic"],a:["Storm Crown","Astral Barrage","Moonlit Mirage"]},
    Merfolk:{p:["Water","Ice","Astral"],m:["Elemental Magic","Spirit Magic"],a:["Frost Prison","Moonlit Mirage","Starfall"]},
    "Pale Orc":{p:["Earth","Ice","Blood"],m:["Ancient Rune Magic","Blood Magic","Elemental Magic"],a:["Frost Prison","Chaos Pulse","Gravity Collapse"]},
    Leonin:{p:["Light","Fire","Earth"],m:["Divine Magic","Elemental Magic","Ancient Rune Magic"],a:["Sunfire Nova","Heavenbreaker","Sacred Sanctuary"]},
    Slime:{p:["Water","Nature","Arcane"],m:["Elemental Magic","Nature Magic","Arcane Magic"],a:["Moonlit Mirage","Arcane Overdrive","Frost Prison"]},
    Reptilian:{p:["Earth","Water","Darkness"],m:["Nature Magic","Elemental Magic","Curse Magic"],a:["Shadow Clone","Death Mark","Moonlit Mirage"]},
    Asgardian:{p:["Lightning","Astral","Holy"],m:["Divine Magic","Celestial Magic","Elemental Magic"],a:["Storm Crown","Heavenbreaker","Celestial Judgment"]},
    "Ancient Egyptian":{p:["Soul","Astral","Light"],m:["Curse Magic","Divine Magic","Spirit Magic"],a:["Spirit Chain","Sacred Sanctuary","Starfall"]},
    God:{p:["Holy","Astral","Time"],m:["Divine Magic","Celestial Magic","Chronomancy"],a:["Celestial Judgment","Sacred Sanctuary","Starfall"]},
    "Demi-God":{p:["Lightning","Fire","Astral"],m:["Divine Magic","Elemental Magic","Celestial Magic"],a:["Heavenbreaker","Storm Crown","Sunfire Nova"]},
    Targaryen:{p:["Fire","Dragon","Astral"],m:["Dragon Magic","Elemental Magic","Ancient Rune Magic"],a:["Dragon Roar","Sunfire Nova","Heavenbreaker"]},
    Dryad:{p:["Nature","Earth","Soul"],m:["Nature Magic","Spirit Magic","Ancient Rune Magic"],a:["Verdant Rebirth","World Tree Blessing","Sacred Sanctuary"]},
    Golem:{p:["Earth","Arcane","Gravity"],m:["Ancient Rune Magic","Arcane Magic","Gravity Magic"],a:["Stoneheart Bastion","Gravity Collapse","Infinite Arsenal"]},
    Kitsune:{p:["Fire","Arcane","Soul"],m:["Illusion Magic","Spirit Magic","Curse Magic"],a:["Foxfire Mirage","Moonlit Mirage","Shadow Clone"]},
    Krakenborn:{p:["Water","Ice","Chaos"],m:["Elemental Magic","Void Magic","Spirit Magic"],a:["Leviathan Surge","Frost Prison","Gravity Collapse"]},
    Djinn:{p:["Fire","Wind","Arcane"],m:["Elemental Magic","Summoning Magic","Ancient Rune Magic"],a:["Wishbound Seal","Sunfire Nova","Astral Barrage"]},
    Oni:{p:["Blood","Lightning","Demonic"],m:["Blood Magic","Curse Magic","Elemental Magic"],a:["Oni Warcry","Blood Dominion","Storm Crown"]},
    Phoenixborn:{p:["Fire","Light","Soul"],m:["Elemental Magic","Divine Magic","Spirit Magic"],a:["Phoenix Ascension","Phoenix Rebirth","Sunfire Nova"]}
  };
  if(p[race]&&chance(.82)){power=rand(p[race].p);magic=rand(p[race].m);ability=rand(p[race].a)}
  if(cls==="Chronomancer"){power="Time";magic="Chronomancy";ability="Time Fracture"}
  if(cls.includes("Void")){power="Void";magic="Void Magic"}
  if(cls.includes("Dragon")){power="Dragon";magic="Dragon Magic"}
  if(cls==="Necromancer"){magic="Necromancy";if(chance(.7))power="Soul"}
  if((cls.includes("Paladin")||cls.includes("Holy"))&&chance(.7)){power="Holy";magic="Divine Magic"}
  if(race==="Demon"&&(power==="Holy"||magic==="Divine Magic"))title="The Heretical Saint";
  if((race==="Angel"||race==="Archangel")&&(power==="Darkness"||magic==="Necromancy"))title="The Fallen Saint";
  if(race==="God"&&rarity.stars>=5)title="The Divine Absolute";
  if(race==="Demi-God"&&rarity.stars>=4)title="The Heaven-Touched";
  if(race==="Targaryen")title=rarity.name==="Primordial"?"Blood of the First Flame":rarity.name==="Mythical"?"Dragonblood Sovereign":"Heir of the Dragonlords";
  if(race==="Dryad")title="Voice of the Worldroot";
  if(race==="Golem")title="The Living Bastion";
  if(race==="Kitsune")title=rarity.stars>=8?"The Nine-Tailed Mirage":"Foxfire Wanderer";
  if(race==="Krakenborn")title="Scion of the Deep";
  if(race==="Djinn")title=rarity.stars>=8?"Sovereign of a Thousand Wishes":"The Wishbound";
  if(race==="Oni")title="Crimson War Spirit";
  if(race==="Phoenixborn")title=rarity.stars>=9?"The Eternal Rebirth":"Heir of the Ember";
  if(rarity.name==="Primordial"&&!title)title=rand(["The First Sovereign","Heir of the Origin","The Unwritten Calamity","Beyond Mortal Law","The Eternal Apex"]);
  return {power,magic,ability,trait,title}
}
function hiddenEvolution(race,cls,rarity){
  const c={Common:0,Uncommon:0,Rare:.003,"Special Rare":.008,"Super Rare":.015,"Super Special Rare":.025,Epic:.05,Legendary:.10,Mythical:.22,Primordial:.45}[rarity.name]||0;
  if(!chance(c))return {race,cls,hiddenRace:false,hiddenClass:false};
  const ev={
    Angel:["High Seraph","Nephilim"],
    Archangel:["Throneseraph","Heaven's Spear"],
    Demon:["Archdemon","Infernal Sovereign"],
    Dragonkin:["Primordial Dragon","Dragon Ascendant"],
    Voidborn:["Eldritch Born","Outer Void Entity"],
    Celestial:["Godborn","Astral Deity"],
    Vampire:["Blood Progenitor","Crimson Ancestor"],
    Elf:["High Fae","World Tree Scion"],
    "Dark Elf":["Abyssal Fae","Night Sovereign"],
    Spiritborn:["Ancient Spirit","Astral Incarnate"],
    Minotaur:["Labyrinth Lord","Horned Titan"],
    Imp:["Infernal Trickster","Hellfire Imp King"],
    Shadow:["Night Incarnate","Eclipse Phantom"],
    Centaur:["Starhoof Champion","Ancient Plains Lord"],
    Ghoul:["Grave Devourer","Carrion King"],
    Ghost:["Spectral Monarch","Wailing Apparition"],
    Undead:["Deathless Sovereign","Bone Tyrant"],
    Lich:["Archlich","Crypt Emperor"],
    Harpy:["Storm Harbinger","Sky Queen"],
    Merfolk:["Tide Oracle","Abyssal Mariner"],
    "Pale Orc":["Frostfang Warlord","Bonecrusher King"],
    Leonin:["Sunmane Sovereign","Golden Pride King"],
    Slime:["Primordial Slime","Abyssal Gel Monarch"],
    Reptilian:["Scaled Tyrant","Basilisk Descendant"],
    Asgardian:["Odinblood Heir","Bifrost Champion"],
    "Ancient Egyptian":["Pharaoh Eternal","Anubian Oracle"],
    God:["Creator Aspect","Divine Origin"],
    "Demi-God":["Ascended Scion","Heaven-Touched Hero"],
    Targaryen:["Dragonlord Ascendant","Blood of Old Valyria"],
    Dryad:["Elder Dryad","Worldroot Avatar"],
    Golem:["Colossus Golem","Genesis Construct"],
    Kitsune:["Nine-Tailed Kitsune","Moonfire Fox Spirit"],
    Krakenborn:["Leviathan Scion","Abyssal Kraken Lord"],
    Djinn:["Ifrit Sovereign","Wishbound Monarch"],
    Oni:["Crimson Oni Lord","Thunder Oni"],
    Phoenixborn:["Eternal Phoenix","Solar Rebirth Avatar"]
  };
  let rr=race,cc=cls,hr=false,hc=false;
  if(ev[race]&&chance(.72)){rr=rand(ev[race]);hr=true}
  const secretClasses=[
    "Reality Breaker","Eternal Vanguard","World Weaver","Seraph Warlord","Divine Arbiter",
    "Abyss Sovereign","Void Monarch","Dragon Emperor","Wyrm Godslayer",
    "Deathlord","Crypt Sovereign","Primal Overlord","Wild King",
    "Grand Arcanist","Sacred Champion","Relic Overlord","Mythic Gunslinger","Ancient Weapon Master"
  ];
  if(chance(.64)||rarity.name==="Primordial"){cc=rand(secretClasses);hc=true}
  return {race:rr,cls:cc,hiddenRace:hr,hiddenClass:hc}
}
function statsFor(c){
  const s={STR:50,AGI:50,INT:50,DEF:50,VIT:50,LCK:50},bonus={1:0,2:4,3:8,4:12,5:17,6:23,7:30,8:38,9:47,10:58}[c.rarity.stars];
  Object.keys(s).forEach(k=>s[k]+=bonus);
  const rm={
    Orc:{STR:15,VIT:10,INT:-6},
    "Pale Orc":{STR:13,VIT:11,INT:-4,DEF:4},
    Dwarf:{DEF:14,VIT:12,AGI:-8},
    Minotaur:{STR:18,VIT:12,AGI:-5},
    Centaur:{STR:10,AGI:10,VIT:8},
    Leonin:{STR:9,AGI:8,VIT:6,LCK:4},
    Slime:{VIT:16,DEF:6,STR:-5,AGI:-3},
    Reptilian:{AGI:9,DEF:5,VIT:6},
    Lich:{INT:18,LCK:8,STR:-8},
    Ghost:{INT:12,AGI:7,DEF:-10},
    Undead:{VIT:14,DEF:7,AGI:-4},
    Harpy:{AGI:13,LCK:6},
    Dragonkin:{STR:12,DEF:9,VIT:10},
    Angel:{INT:10,AGI:5,LCK:6},
    Archangel:{INT:15,AGI:8,LCK:12,DEF:5},
    Elf:{AGI:10,INT:8,DEF:-4},
    Demon:{STR:12,INT:6},
    Vampire:{AGI:8,INT:6,LCK:5},
    Voidborn:{INT:13,LCK:8},
    Asgardian:{STR:10,INT:10,VIT:8,LCK:6},
    "Ancient Egyptian":{INT:9,LCK:8,AGI:4},
    God:{STR:10,AGI:6,INT:16,VIT:10,LCK:12},
    "Demi-God":{STR:12,AGI:8,INT:8,LCK:6}
  };
  const cm={Knight:{STR:8,DEF:10,VIT:6},Paladin:{STR:6,DEF:8,VIT:8,INT:4},Mage:{INT:16,DEF:-5},Ranger:{AGI:12,LCK:5},Assassin:{AGI:16,LCK:7,DEF:-7},Berserker:{STR:18,VIT:8},Priest:{INT:12,VIT:5},Necromancer:{INT:15,LCK:4,DEF:-5},Chronomancer:{INT:16,AGI:7,LCK:5},"Dragon Knight":{STR:12,DEF:8,VIT:7},"Void Walker":{INT:14,AGI:7,LCK:6}};
  for(const [k,v] of Object.entries(rm[c.baseRace]||{}))s[k]+=v;
  for(const [k,v] of Object.entries(cm[c.baseClass]||{}))s[k]+=v;
  Object.keys(s).forEach(k=>s[k]=Math.max(10,Math.min(120,Math.round(s[k]))));
  return s
}
function makeLore(c){
  const origins=[
    `Born in ${c.origin}, this figure was shaped by conflict, magic, and destiny.`,
    `This character emerged from ${c.origin}, a land filled with ancient legends and hidden dangers.`,
    `Their story began in ${c.origin}, long before their name became known among adventurers.`
  ];
  const identity=[
    `As a ${c.class} of the ${c.race} race, they command ${c.magicType.toLowerCase()} and are known for the ability ${c.ability}.`,
    `Their path as a ${c.class} is intertwined with ${c.magicType.toLowerCase()}, while the ${c.weapon} serves as their primary weapon.`,
    `Their affinity with ${c.powerType.toLowerCase()} and mastery of ${c.ability} make them an unpredictable opponent.`
  ];
  const rarityLore={
    Common:"Their potential is only beginning to reveal itself.",
    Uncommon:"Their reputation is starting to spread among adventurers.",
    Rare:"Their name has already entered the records of their homeland.",
    "Special Rare":"Their abilities are considered unusual even among experienced warriors.",
    "Super Rare":"Stories of their power have begun spreading across multiple regions.",
    "Super Special Rare":"Their name is being recorded as an extraordinary figure in local history.",
    Epic:"Their deeds are beginning to appear in the chronicles of kingdoms.",
    Legendary:"They have already become a living legend.",
    Mythical:"Their very existence is spoken of as something close to myth.",
    Primordial:"They are regarded as an existence that transcends the boundaries of recorded history."
  };
  return `${rand(origins)} ${rand(identity)} ${rarityLore[c.rarity.name]} The trait ${c.trait} is believed to play a decisive role in their destiny.`;
}
function comboTitle(c,fallback){
  const t=[
    [c.hiddenRace&&c.hiddenClass,"The Impossible Ascendant"],
    [c.powerType==="Time"&&c.baseClass==="Assassin","The Blade Between Seconds"],
    [c.powerType==="Void"&&c.magicType==="Chronomancy","The End of All Hours"],
    [c.trait==="Six-Winged Awakening","The Six-Winged Omen"],
    [c.rarity.name==="Primordial"&&c.powerType==="Void","Beyond the Last Horizon"],
    [c.baseRace==="God","Crown of the Infinite"],
    [c.baseRace==="Demi-God","Scion of Heaven"],
    [c.baseRace==="Asgardian","Storm of Valhalla"],
    [c.baseRace==="Ancient Egyptian","Keeper of the Eternal Sun"],
    [c.baseRace==="Leonin","Lord of the Golden Pride"],
    [c.baseRace==="Slime","The Gelatinous Miracle"],
    [c.baseRace==="Targaryen","The Last Dragonlord"],
    [c.baseRace==="Dryad","Keeper of the First Grove"],
    [c.baseRace==="Golem","The Unmoving World"],
    [c.baseRace==="Kitsune","The Thousand-Faced Flame"],
    [c.baseRace==="Krakenborn","Lord of the Sunless Sea"],
    [c.baseRace==="Djinn","The Unbound Wish"],
    [c.baseRace==="Oni","The Crimson Calamity"],
    [c.baseRace==="Phoenixborn","The Flame That Returns"]
  ];
  for(const [ok,x] of t)if(ok)return x;return fallback
}
function generateCharacter(seedInput=makeSeed(),forcedRarityName=null){
  const seed=normalizeSeed(seedInput)||makeSeed();
  const oldRng=rng;
  rng=mulberry32(hashSeed(seed));
  try{
    const forced=forcedRarityName?RARITIES.find(r=>r.name===forcedRarityName):null;
    const rarity=forced||rarityRoll(),baseRace=pickRace(rarity.name,seed),baseClass=pickClassForSeed(seed),syn=synergy(baseRace,baseClass,rarity),e=hiddenEvolutionV163(baseRace,baseClass,rarity,seed);
    let title=syn.title||(rarity.stars>=5?rand(["The Starforged","The Unbroken","The Silent Crown","The Dawnless One"]):rand(["Wandering Blade","Arcane Seeker","Iron Vanguard","Moonstrider","Ashborn"]));
    const c={customName:"",seed,characterId:characterIdFromSeed(seed),rarity,baseRace,baseClass,race:e.race,raceCategory:raceFamily(baseRace),class:e.cls,hiddenRace:e.hiddenRace,hiddenClass:e.hiddenClass,gender:rand(DATA.genders),age:ageForRace(baseRace),origin:pickOrigin(),subclass:rand(DATA.subclasses),faction:rand(DATA.factions),affinity:rand(DATA.affinities),ability:syn.ability,ultimate:rand(DATA.ultimates),passive:rand(DATA.passives),powerType:syn.power,magicType:syn.magic,weapon:pickWeaponForSeed(seed),trait:pickTraitForSeed(seed,syn.trait),personality:rand(DATA.personalities),alignment:rand(DATA.alignments)};
    c.rarityChance=rarity.w;
    c.raceChance=raceProbability(baseRace,rarity.name,seed);
    c.title=comboTitle(c,title);c.stats=statsFor(c);c.lore=makeLore(c);
    Object.assign(c,generateWeaponProfile(c.weapon,c.seed));
    c.equipment=generateEquipmentLoadout(c.seed);
    ensureProgression(c);
    c.combatPower=computeCombatPower(c);
    c.overallRating=overallRatingFromPower(c.combatPower);
    return c;
  }finally{rng=oldRng}
}
function displayName(c){return c&&c.customName&&c.customName.trim()?c.customName.trim():"UNNAMED HERO"}
function buildPrompt(c){
  const name=displayName(c);
  const ageNumber=Number(c.age)||0;
  const ageMood=ageNumber<=17?"youthful":"mature";
  const buildByGender={
    Male:"natural proportions and practical fantasy clothing",
    Female:"natural proportions and practical fantasy clothing"
  };
  const raceLook={
    Human:"realistic human features and a grounded fantasy presence",
    Elf:"refined features, elegant pointed ears, and graceful high-fantasy styling",
    "Dark Elf":"sharp refined features, dark mystical elegance, and a dangerous arcane aura",
    Spiritborn:"an ethereal spiritual presence with supernatural energy",
    Beastkin:"animalistic traits blended naturally with humanoid anatomy",
    Celestial:"radiant divine features and luminous heavenly motifs",
    Dragonkin:"draconic traits, subtle scales, and proud dragon-inspired details",
    Demon:"demonic traits, infernal accents, and an intimidating supernatural aura",
    Angel:"holy radiant beauty and elegant celestial details",
    Archangel:"majestic divine features and an exalted heavenly presence",
    "Demi-God":"semi-divine heroic features and regal supernatural presence",
    God:"overwhelming divine majesty and transcendent presence",
    Targaryen:"noble silver-blonde high-bloodline features with subtle dragon-lord motifs",
    Orc:"rugged powerful orcish features and savage warrior presence",
    "Pale Orc":"pale intimidating orcish features and brutal fantasy detailing",
    Dwarf:"sturdy compact proportions and master-crafted fantasy styling",
    Leonin:"lion-like regal features and commanding beast-warrior presence",
    Slime:"a humanoid slime-inspired form with translucent magical accents",
    Reptilian:"reptilian traits, natural scale textures, and predatory presence",
    Shadow:"shadow-infused features and dark spectral energy",
    Centaur:"centaur-inspired anatomy with a grand fantasy warrior presence",
    Ghoul:"grim undead features and dark-fantasy details",
    Ghost:"spectral translucent traits and ghostly supernatural energy",
    Undead:"cursed undead features and ancient dark-fantasy details",
    Vampire:"aristocratic dark beauty and refined vampiric elegance",
    Fairy:"delicate magical traits and graceful fairy motifs",
    Harpy:"avian fantasy traits and fierce aerial elegance",
    Phoenixborn:"phoenix-inspired details, fiery grandeur, and rebirth motifs",
    Krakenborn:"abyssal oceanic traits and deep-sea fantasy styling",
    Merfolk:"aquatic elegance and refined oceanic motifs",
    Kitsune:"fox-spirit traits, mystic charm, and elegant supernatural styling",
    Oni:"powerful oni traits and intimidating mythic strength",
    Djinn:"mystical spirit features and flowing magical energy motifs",
    Lich:"arcane undead sovereignty and forbidden magical prestige",
    Golem:"ancient construct traits with stone or arcane-material detailing",
    "Fallen Angel":"celestial beauty corrupted by dark power",
    Asgardian:"heroic divine-norse features and legendary warrior nobility",
    "Ancient Egyptian":"ancient Egyptian royal motifs and sacred mythological styling",
    Imp:"small demonic traits and mischievous infernal styling",
    Minotaur:"massive horned traits and imposing warrior strength",
    Voidborn:"eldritch cosmic traits and reality-warped void energy",
    Dryad:"nature-bound beauty with elegant botanical motifs"
  };
  const rarityStyle={
    Common:"simple, grounded fantasy detailing",
    Uncommon:"light premium accents",
    Rare:"refined premium detailing",
    "Special Rare":"elegant magical accents",
    "Super Rare":"rich high-tier detailing",
    "Super Special Rare":"prestigious ornate detailing",
    Epic:"elite high-fantasy detailing",
    Legendary:"luxurious legendary detailing",
    Mythical:"majestic mythic detailing",
    Primordial:"transcendent primordial detailing"
  };
  const buildDesc=buildByGender[c.gender]||"balanced and well-proportioned";
  const raceDesc=raceLook[c.baseRace||c.race]||`${c.race.toLowerCase()} fantasy traits`;
  const raceFamilyValue=c.raceCategory||raceFamily(c.baseRace);
  const footer=`Character ID: ${c.characterId} | Character Seed: ${c.seed} | Race: ${c.race}${c.hiddenRace?" [HIDDEN RACE]":""} | Race Family: ${raceFamilyValue} | Rarity: ${c.rarity.name} | Combat Power: ${c.combatPower}`;
  return `Create an ultra-realistic 8K character splash art in a 3:4 aspect ratio, using a hyper-realistic AAA Game style with character rendering quality inspired by Tekken 8. Use English only for visible text. Show the character full-body, centered, occupying about 75% of the frame. At the TOP, display the custom name in bold stylish text: "${name}". At the BOTTOM, create a clean premium footer displaying exactly: "${footer}". Character direction: ${ageMood} ${c.gender.toLowerCase()}, ${buildDesc}, in a dynamic, strong, and tough pose. Race: ${c.race}; emphasize ${raceDesc}. Class: ${c.class}${c.hiddenClass?" [HIDDEN CLASS]":""}, Subclass: ${c.subclass}. Origin: ${c.origin}. Faction: ${c.faction}. Affinity: ${c.affinity}. Rarity treatment: ${rarityStyle[c.rarity.name]||"premium fantasy detailing"}. Weapon: ${c.weapon} (${c.weaponCategory}, ${c.weaponRarity.name}). Equipment cues: ${c.equipment.armor.name}, ${c.equipment.accessory.name}, ${c.equipment.relic.name}, ${c.equipment.artifact.name}. Power theme: ${c.powerType} / ${c.magicType}. Ability focus: ${c.ability}, ${c.ultimate}, ${c.passive}. Design the costume, armor, accessories, weapon, silhouette, hairstyle, expression, aura, and effects so they naturally reflect the generated race, class, equipment, affinity, and power theme. Use an aesthetic clean dark background only: minimal, plain, and dark, with no scenery, architecture, landscape, props, decorative objects, or extra background elements. Keep all visual energy around the character. Use dramatic lighting, sharp costume detail, realistic materials, and cinematic shadows. Ensure realistic anatomy, natural hands, exactly five fingers on each visible hand, correct hand orientation, no extra limbs, and no distorted proportions. Negative Prompt: Bad anatomy, multiple fingers, extra fingers, fused fingers, missing fingers, cartoon, anime, blurred subjects, blurry subject, multiple hands, extra limbs, malformed hands, reversed hands, backward hands, twisted wrists, distorted proportions, low detail, low resolution.`
}
function serverCharacterFromRow(row,legacy=null){
  const c=generateCharacter(row.seed,row.rarity_name);
  ensureAdvancedData(c);
  c.serverOwned=true;
  c.serverRegistryId=row.registry_id;
  c.serverSessionId=row.summon_session_id||null;
  c.serverCreatedAt=row.created_at||null;
  c.favorite=!!row.favorite;
  c.customName=String(row.custom_name||"").slice(0,48);
  c.savedAt=row.created_at?Date.parse(row.created_at):Date.now();
  c.summonedAt=c.savedAt;
  c.serverGpReward=Number(row.gp_reward)||0;
  c.serverSummonIndex=Number(row.summon_index)||1;

  // V16.3B: Supabase is authoritative for progression.
  c.progression={
    ...(c.progression||{}),
    level:Math.max(1,Math.min(100,Number(row.character_level)||1)),
    xp:Math.max(0,Number(row.character_xp)||0),
    stage:Math.max(0,Math.min(3,Number(row.evolution_stage)||0))
  };
  c.weaponUpgrade=Math.max(0,Math.min(10,Number(row.weapon_upgrade)||0));
  if(c.equipment?.armor)c.equipment.armor.upgrade=Math.max(0,Math.min(10,Number(row.armor_upgrade)||0));
  if(c.equipment?.accessory)c.equipment.accessory.upgrade=Math.max(0,Math.min(10,Number(row.accessory_upgrade)||0));
  if(c.equipment?.relic)c.equipment.relic.upgrade=Math.max(0,Math.min(10,Number(row.relic_upgrade)||0));
  if(c.equipment?.artifact)c.equipment.artifact.upgrade=Math.max(0,Math.min(10,Number(row.artifact_upgrade)||0));
  ensureAdvancedData(c);
  return c;
}
function nativeReconstruct(row){return JSON.stringify(serverCharacterFromRow(JSON.parse(row)));}
function nativePrompt(character){return buildPrompt(JSON.parse(character));}
function nativeCatalog(){return JSON.stringify({data:DATA,families:RACE_FAMILIES,rarities:RARITIES,achievements:ACHIEVEMENTS,missions:DAILY_MISSION_POOL,login:LOGIN_REWARDS,stages:ASCENSION_STAGES});}

function nativeStats(character){return JSON.stringify(effectiveStats(JSON.parse(character)));}
