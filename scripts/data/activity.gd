class_name Activity
extends Resource
## Mot hoat dong. Them hoat dong = them file .tres trong data/activities/.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## So phut game bi tieu ton.
@export var minutes: int = 30
## Suc luc phai tra.
@export var energy_cost: float = 5.0
## Tien phai tra (VND).
@export var money_cost: int = 0
## Tien nhan duoc (VND).
@export var money_gain: int = 0
## Hieu ung len chi so: {"mood": 5, "skill": 2, "money": -25000}
@export var stat_effects: Dictionary = {}
## Cong vao so phut tu hoc cua mon nay (dung cho study).
@export var study_minutes: int = 0
## Mon hoc ma hoat dong nay ap dung (rong = moi mon).
@export var course_id: String = ""
## Ngu: nhay sang ngay hom sau.
@export var is_sleep: bool = false
