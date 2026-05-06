export type FriendshipStatus = 'pending' | 'accepted'
export type RecordMethod = 'now' | 'manual'

export interface Profile {
  id: string
  username: string
  display_name: string | null
  push_token: string | null
  created_at: string
}

export interface Friendship {
  id: string
  requester_id: string
  addressee_id: string
  status: FriendshipStatus
  created_at: string
}

export interface FriendShare {
  user_id: string
  friend_id: string
  created_at: string
}

export interface SleepRecord {
  id: string
  user_id: string
  date: string             // 'YYYY-MM-DD' — 起床した日付
  bedtime_at: string | null  // ISO 8601 UTC
  bedtime_method: RecordMethod | null
  wake_at: string | null     // ISO 8601 UTC
  wake_method: RecordMethod | null
  created_at: string
}

export interface SleepGoal {
  id: string
  user_id: string
  target_date: string       // 'YYYY-MM-DD'
  target_bedtime: string    // 'HH:MM:SS'
  target_wake_time: string  // 'HH:MM:SS'
  daily_goal: string | null
  created_at: string
}

export interface FriendSleepView {
  profile: Profile
  is_shared: boolean
  goal: SleepGoal | null
  record: Pick<SleepRecord, 'date' | 'bedtime_at' | 'wake_at'> | null
  achieved: boolean | null
}
