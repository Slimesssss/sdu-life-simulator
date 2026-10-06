extends Node
## Tram phat signal toan cuc.
##
## Quy uoc: EventBus CHI khai bao signal, TUYET DOI khong chua logic.
## He thong nao muon bao cho he thong khac biet thi phat signal o day,
## nho vay khong phai di tim node bang get_node("../../..").

## Dong ho game vua sang phut moi. `clock` la GameClock.snapshot().
signal time_changed(clock: Dictionary)

## Sang ngay moi.
signal day_started(clock: Dictionary)

## Mot hoat dong vua duoc thuc hien xong.
signal activity_performed(activity_id: String)

## Mot chi so nguoi choi vua doi.
signal stat_changed(stat_name: String, value: float)

## Hien mot dong thong bao ngan tren HUD.
signal toast(text: String)

## Doi dong goi y tuong tac ("[E] Ngu").
signal prompt_changed(text: String)

## Khoa / mo dieu khien nguoi choi (hoi thoai, minigame, ngu...).
signal input_lock_changed(locked: bool)

## Game vua duoc luu / tai.
signal game_saved(slot: int)
signal game_loaded(slot: int)

## Thi xong mot mon. `score` da lam tron.
signal exam_finished(course_id: String, score: float)

## Nguoi choi doi khu / doi scene.
signal zone_entered(zone_id: String)

## Ngu xong — phat bang tong ket cuoi ngay (GDD 3.13.3).
signal day_summary(summary: Dictionary)
