class_name Course
extends Resource
## Mot mon hoc. File that: data/courses/*.tres

@export var id: String = ""
@export var display_name: String = ""
@export var credits: int = 3

## So phut tu hoc can de dat prep = 1.0. Mon kho doi nhieu hon.
## Goi y: 600 de / 900 vua / 1200 kho.
@export var required_minutes: int = 900

@export_enum("de", "vua", "kho") var difficulty: String = "vua"
@export_enum("trac_nghiem", "tu_luan") var exam_format: String = "trac_nghiem"

## Tiet hoc trong tuan: [{"weekday": 0, "minute": 450}]
## weekday: 0 = Thu 2 ... 6 = Chu nhat. minute: phut trong ngay (450 = 07:30).
@export var class_slots: Array[Dictionary] = []
