import { Link } from 'expo-router';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { useAuth } from '@/context/AuthContext';

export default function HomeScreen() {
  const { user, loading, logout } = useAuth();

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#2563eb" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.brand}>Navodayan</Text>
      <Text style={styles.subtitle}>
        Connect with alumni, students, and teachers from JNVs worldwide.
      </Text>

      {user ? (
        <Text style={styles.welcome}>Signed in as {user.email}</Text>
      ) : (
        <Text style={styles.welcome}>Browse the community from your phone.</Text>
      )}

      <Link href="/directory" asChild>
        <Pressable style={styles.primaryButton}>
          <Text style={styles.primaryButtonText}>Browse Directory</Text>
        </Pressable>
      </Link>

      {user ? (
        <Pressable style={styles.secondaryButton} onPress={logout}>
          <Text style={styles.secondaryButtonText}>Logout</Text>
        </Pressable>
      ) : (
        <>
          <Link href="/login" asChild>
            <Pressable style={styles.secondaryButton}>
              <Text style={styles.secondaryButtonText}>Login</Text>
            </Pressable>
          </Link>
          <Link href="/register" asChild>
            <Pressable style={styles.secondaryButton}>
              <Text style={styles.secondaryButtonText}>Join Network</Text>
            </Pressable>
          </Link>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    justifyContent: 'center',
    gap: 12,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  brand: {
    fontSize: 36,
    fontWeight: '800',
    color: '#111827',
  },
  subtitle: {
    fontSize: 16,
    color: '#6b7280',
    marginBottom: 12,
    lineHeight: 24,
  },
  welcome: {
    fontSize: 15,
    color: '#374151',
    marginBottom: 8,
  },
  primaryButton: {
    backgroundColor: '#2563eb',
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  primaryButtonText: {
    color: '#ffffff',
    fontWeight: '700',
    fontSize: 16,
  },
  secondaryButton: {
    backgroundColor: '#ffffff',
    borderWidth: 1,
    borderColor: '#e5e7eb',
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  secondaryButtonText: {
    color: '#111827',
    fontWeight: '700',
    fontSize: 16,
  },
});
