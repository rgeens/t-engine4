return {
	name = "Minas Tirith",
	level_range = {15, 15},
	max_level = 1,
	width = 196, height = 80,
	all_remembered = true,
	all_lited = true,
	generator =  {
		map = {
			class = "engine.generator.map.Static",
			map = "towns/minas-tirith",
		},
		actor = {
			class = "engine.generator.actor.Random",
			nb_npc = {0, 0},
		},
		object = {
			class = "engine.generator.object.Random",
			nb_object = {0, 0},
		},
	}
}
