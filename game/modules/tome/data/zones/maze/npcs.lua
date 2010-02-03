load("/data/general/npcs/vermin.lua")
load("/data/general/npcs/canine.lua")
load("/data/general/npcs/troll.lua")
load("/data/general/npcs/snake.lua")
load("/data/general/npcs/ooze.lua")
load("/data/general/npcs/jelly.lua")

local Talents = require("engine.interface.ActorTalents")

-- The boss of trollshaws, no "rarity" field means it will not be randomly generated
newEntity{ define_as = "TROLL_BILL",
	type = "giant", subtype = "troll", unique = true,
	name = "Bill the Stone Troll",
	display = "T", color=colors.VIOLET,
	desc = [[Big, brawny, powerful and with a taste for hobbit. He has friends called Bert and Tom.
	He is wielding a small tree trunk and towering toward you.
	He should have turned to stone long ago, how could he still walk?!]],
	level_range = {7, 10}, exp_worth = 2,
	max_life = 250, life_rating = 17, fixed_rating = true,
	max_stamina = 85,
	stats = { str=25, dex=10, cun=8, mag=10, con=20 },

	body = { INVEN = 10, MAINHAND=1, OFFHAND=1, BODY=1 },
	equipment = resolvers.equip{ {type="weapon", subtype="greatmaul", defined="GREATMAUL_BILL_TRUNK"}, },
	drops = resolvers.drops{chance=100, nb=3, {ego_chance=100} },

	talents = resolvers.talents{
		[Talents.T_STAMINA_POOL]=1, [Talents.T_STUN]=2, [Talents.T_KNOCKBACK]=1,
	},

	autolevel = "warrior",
	ai = "dumb_talented_simple", ai_state = { talent_in=4, },
}
