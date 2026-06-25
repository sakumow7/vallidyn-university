class_name Strike
extends Action
## The Strike action (spec §4.1, §4.5): an attack roll through the universal [Check]
## (carrying MAP and the attacker's conditions), hit/crit decided by degree of
## success, damage with crit doubling, then the target's resistance/weakness/
## immunity. This is the first action to CONSUME conditions — the defender's off-guard
## lowers its AC; the attacker's frightened/enfeebled/clumsy bite the attack roll.

const _AC_CONTEXT := [Ids.StatTag.AC, Ids.StatTag.DEX_BASED]

var weapon: WeaponProfile


func _init(p_weapon: WeaponProfile) -> void:
	super("Strike", Ids.ActionCost.ONE, [&"attack"])
	weapon = p_weapon


## A fully described Strike outcome — the precursor to the general ActionResult (M12)
## the combat scene will animate.
class Result:
	extends RefCounted

	var performed: bool = false        ## false if there was no action to spend
	var attack: Check.Result = null
	var hit: bool = false
	var critical: bool = false
	var map_applied: int = 0
	var target_ac: int = 0             ## the effective AC the attack resolved against
	var damage: int = 0                ## final damage dealt, after mitigation
	var damage_type: StringName = &""
	var damage_roll: Dice.Roll = null

	func _to_string() -> String:
		if not performed:
			return "Strike: no action available"
		var head := "Strike %s" % ("CRIT" if critical else ("hit" if hit else "miss"))
		if hit:
			return "%s for %d %s  (%s)" % [head, damage, damage_type, attack]
		return "%s  (%s)" % [head, attack]


## Resolve this Strike by [param attacker] against [param defender], rolling with the
## injected [param rng]. If [param economy] is non-null it gates the action and is
## charged (1 action) and advances MAP; pass null to resolve a Strike in isolation.
func resolve(
		attacker: Creature,
		defender: Creature,
		economy: ActionEconomy,
		rng: RandomNumberGenerator) -> Result:
	var result := Result.new()
	if economy != null and not economy.can_spend(cost_value()):
		return result            # performed stays false
	result.performed = true

	var map := 0
	if economy != null:
		map = economy.map_penalty(weapon.agile)
	result.map_applied = map

	# Defender's AC already folds in its conditions (off-guard, frightened, clumsy…).
	var effective_ac := defender.effective_ac()
	result.target_ac = effective_ac

	# Attack roll: the weapon's to-hit bonus and MAP are untyped; the attacker's
	# conditions emit their own typed modifiers and resolve in the stack.
	var stack := ModifierStack.new()
	stack.add(Modifier.new(weapon.attack_bonus, Ids.ModifierType.UNTYPED, &"attack"))
	if map != 0:
		stack.add(Modifier.new(map, Ids.ModifierType.UNTYPED, &"MAP"))
	stack.add_all(attacker.conditions.modifiers_for(weapon.attack_tags))

	var atk := Check.roll(effective_ac, 0, 0, stack, rng)
	result.attack = atk
	result.hit = atk.is_success()
	result.critical = atk.is_critical_success()

	if result.hit:
		var roll := Dice.roll(weapon.damage_formula, rng)
		var raw := roll.total + weapon.damage_bonus
		if result.critical:
			raw *= 2                  # crit doubles dice + bonuses, before mitigation
		result.damage_roll = roll
		result.damage_type = weapon.damage_type
		result.damage = defender.apply_damage(raw, weapon.damage_type)

	if economy != null:
		economy.spend(cost_value())
		economy.note_attack()
	return result
