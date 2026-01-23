extends Node
## ResourceRegistry.gd
## explicitly holds references to resources so they are exported and accessible without DirAccess scanning.

# TASKS
const TASK_FILES = [
	preload("res://resources/tasks/Task_01_Origins.tres"),
	preload("res://resources/tasks/Task_02_Evolution.tres"),
	preload("res://resources/tasks/Task_03_Safety.tres"),
	preload("res://resources/tasks/Task_04_Stability.tres"),
	preload("res://resources/tasks/Task_05_Swarm.tres"),
	preload("res://resources/tasks/Task_06_FirstDino.tres"),
	preload("res://resources/tasks/Task_07_Colonize.tres"),
	preload("res://resources/tasks/Task_08_Grazers.tres"),
	preload("res://resources/tasks/Task_09_Predator.tres"),
	preload("res://resources/tasks/Task_10_PackHunt.tres"),
	preload("res://resources/tasks/Task_11_Speed.tres"),
	preload("res://resources/tasks/Task_12_Reach.tres"),
	preload("res://resources/tasks/Task_13_Wall.tres"),
	preload("res://resources/tasks/Task_14_King.tres"),
	preload("res://resources/tasks/Task_15_Tank.tres"),
	preload("res://resources/tasks/Task_16_Clash.tres")
]

# TRAITS
const TRAIT_FILES = [
	preload("res://resources/traits/Trait_CranialCrest.tres"),
	preload("res://resources/traits/Trait_ElongatedNeck.tres"),
	preload("res://resources/traits/Trait_FusedAnkles.tres"),
	preload("res://resources/traits/Trait_Gastroliths.tres"),
	preload("res://resources/traits/Trait_Gigantism.tres"),
	preload("res://resources/traits/Trait_HollowBones.tres"),
	preload("res://resources/traits/Trait_Intramandibular.tres"),
	preload("res://resources/traits/Trait_LeafShapedTeeth.tres"),
	preload("res://resources/traits/Trait_PerforateAcetabulum.tres"),
	preload("res://resources/traits/Trait_Quadrupedalism.tres"),
	preload("res://resources/traits/Trait_SerratedTeeth.tres"),
	preload("res://resources/traits/Trait_UprightStance.tres")
]

# HABITATS
const HABITAT_FILES = [
	preload("res://resources/habitats/Habitat_Cycads.tres"),
	preload("res://resources/habitats/Habitat_Ferns.tres"),
	preload("res://resources/habitats/Habitat_Forest.tres"),
	preload("res://resources/habitats/Habitat_Pools.tres"),
	preload("res://resources/habitats/Habitat_River.tres")
]
