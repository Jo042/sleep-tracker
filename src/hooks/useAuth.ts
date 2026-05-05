import { useAuthStore } from '@/store/authStore'

// signInWithApple・signOut の実装は Phase 3 で追加する
export function useAuth() {
  const { session, user, isLoading } = useAuthStore()

  async function signInWithApple(): Promise<void> {
    throw new Error('Phase 3 で実装予定')
  }

  async function signOut(): Promise<void> {
    throw new Error('Phase 3 で実装予定')
  }

  return { session, user, isLoading, signInWithApple, signOut }
}
