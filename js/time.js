// time.js – Hệ thống thời gian & lịch học – SDU Life Simulator

const Time = (() => {
  let _hour = 6, _day = 1, _week = 1, _semester = 1;
  let _accum = 0;
  const MS_PER_HOUR = 60000; // 1 phút thực = 1 giờ game
  const _cbs = [];
  const DOW = ['','Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','CN'];

  function _emit(evt, arg) { _cbs.forEach(f => f(evt, arg)); }

  function getDow() { return ((_day - 1) % 7) + 1; }
  function isWeekday() { return getDow() <= 5; }

  function getScheduleToday() {
    return DATA.SCHEDULE.filter(s => s.dow === getDow());
  }

  function getCurrentClass() {
    if (!isWeekday()) return null;
    for (const s of getScheduleToday()) {
      const p = DATA.PERIODS[s.period];
      if (_hour >= p.start && _hour < p.end) return s;
    }
    return null;
  }

  function getNextClass() {
    if (!isWeekday()) return null;
    return getScheduleToday()
      .sort((a,b)=>a.period-b.period)
      .find(s => DATA.PERIODS[s.period].start > _hour) || null;
  }

  function advance(hours) {
    _hour += hours;
    while (_hour >= 24) {
      _hour -= 24;
      _day++;
      _week = Math.ceil(_day / 7);
      if (_week > 16) { _week = 1; _day = 1; _semester++; _emit('newSemester'); }
      else _emit('newDay');
    }
    _emit('hourPassed', hours);
  }

  function update(dt) {
    _accum += dt;
    if (_accum >= MS_PER_HOUR) {
      const n = Math.floor(_accum / MS_PER_HOUR);
      _accum -= n * MS_PER_HOUR;
      advance(n);
    }
  }

  function onEvent(cb) { _cbs.push(cb); }
  function getTimeStr() { return `${String(Math.floor(_hour)).padStart(2,'0')}:00`; }
  function getDayStr() { return `${DOW[getDow()]}  |  Tuần ${_week}  |  HK${_semester}`; }
  function reset() { _hour=6;_day=1;_week=1;_semester=1;_accum=0; }
  function getAll() { return {hour:_hour,day:_day,week:_week,semester:_semester,dow:getDow()}; }

  return {
    update, advance, onEvent, reset,
    getTimeStr, getDayStr, getAll,
    getDow, isWeekday, getScheduleToday, getCurrentClass, getNextClass,
    get hour(){return _hour},
    get week(){return _week},
    get day(){return _day},
    get semester(){return _semester},
    isExamWeek(){ return _week >= 15; },
    isMidtermWeek(){ return _week === 8; },
  };
})();
