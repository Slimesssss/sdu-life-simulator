class_name BalanceConfig
extends Resource
## Moi hang so can chinh khi playtest. Sua qua Inspector, khong can sua code.
## File that: res://data/balance.tres

# --- Cong thuc diem thi (GDD 3.4) ---
@export_group("Diem thi")
@export var prep_weight: float = 0.45
@export var minigame_weight: float = 0.35
@export var knowledge_weight: float = 0.10
@export var attendance_weight: float = 0.10
## prep = study_minutes * (1 + int_bonus * tri_tue/100) / required_minutes
@export var int_bonus: float = 0.5
## form = form_min + (form_max - form_min) * min(suc_khoe, tinh_than)/100
@export var form_min: float = 0.8
@export var form_max: float = 1.0
## Lam tron diem theo buoc nay (0.5 nhu bang diem Viet Nam)
@export var score_step: float = 0.5

# --- Nguong ---
@export_group("Nguong")
@export var pass_score: float = 4.0
@export var retake_cap: float = 8.0
@export var milestone_step: int = 10

# --- Chi so khoi dau nguoi choi ---
@export_group("Chi so khoi dau")
@export var start_stamina: float = 100.0
@export var start_health: float = 80.0
@export var start_mood: float = 80.0
@export var start_intelligence: float = 20.0
@export var start_academic: float = 30.0
@export var start_skill: float = 10.0
@export var start_money: int = 5_000_000
@export_group("Dong ho")
@export var minutes_per_real_second: float = 6.0
@export var day_start_minute: int = 6 * 60
@export var week_days: int = 7

# --- Kinh te (VND) ---
@export_group("Kinh te")
@export var family_monthly: int = 3_000_000
@export var part_time_pay: int = 200_000
@export var it_job_pay: int = 350_000
@export var tuition_per_term: int = 9_000_000
@export var meal_cost: int = 25_000
@export var instant_noodle_cost: int = 10_000
@export var rent_a: int = 1_200_000
@export var rent_b: int = 800_000
@export var rent_c: int = 500_000
