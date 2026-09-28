extends Node

# player health variables
var max_health: int = 100
var health: int = 100 

func reset() -> void:
	health = max_health
