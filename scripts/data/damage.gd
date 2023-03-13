class_name Damage


enum DamageType {
	INDISCRIMINANT,
	AVIAN_INDISCRIMINANT,
}


var damage_type : DamageType
var amount : float


## Private methods ##

func _init(damage_type_ : DamageType, amount_ : float) -> void:
	damage_type = damage_type_
	amount = amount_


## Public methods ##

func is_avian() -> bool:
	return damage_type in [
		DamageType.AVIAN_INDISCRIMINANT
	]
