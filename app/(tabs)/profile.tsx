import { View, Text, StyleSheet } from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'

export default function ProfileScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.heading}>Profile</Text>
        <Text style={styles.placeholder}>Phase 9 で設定・サインアウトを実装</Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 20 },
  heading: { fontSize: 28, fontWeight: '700', marginBottom: 8 },
  placeholder: { fontSize: 14, color: '#999' },
})
