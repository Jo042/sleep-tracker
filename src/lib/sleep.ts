import { format, parseISO, addDays } from 'date-fns'

export function getTodayDate(): string {
  return format(new Date(), 'yyyy-MM-dd')
}

export function getTomorrowDate(): string {
  return format(addDays(new Date(), 1), 'yyyy-MM-dd')
}

// ISO タイムスタンプをローカル時刻の HH:mm 形式に変換
export function formatLocalTime(isoString: string): string {
  return format(parseISO(isoString), 'HH:mm')
}

// DB の time 型 ('HH:MM:SS') を表示用 'HH:mm' に変換
export function formatTimeField(timeString: string): string {
  return timeString.slice(0, 5)
}

// 睡眠時間を時間単位で計算
export function calcSleepDurationHours(bedtimeAt: string, wakeAt: string): number {
  return (parseISO(wakeAt).getTime() - parseISO(bedtimeAt).getTime()) / 3_600_000
}

// 達成判定: 目標時刻 ±30分以内を「達成」とする
export function isGoalAchieved(
  targetTime: string,  // 'HH:MM:SS'
  actualAt: string,    // ISO UTC
  targetDate: string   // 'YYYY-MM-DD'
): boolean {
  const [h, m] = targetTime.split(':').map(Number)
  const target = parseISO(targetDate)
  target.setHours(h, m, 0, 0)
  const diff = Math.abs(parseISO(actualAt).getTime() - target.getTime())
  return diff <= 30 * 60 * 1000
}
