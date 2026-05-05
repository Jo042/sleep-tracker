import { Redirect, Stack } from 'expo-router'
import { useAuthStore } from '@/store/authStore'

export default function AuthLayout() {
  const { session, isLoading } = useAuthStore()

  if (isLoading) return null
  if (session) return <Redirect href="/(tabs)" />

  return <Stack screenOptions={{ headerShown: false }} />
}
