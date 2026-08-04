import { useState } from 'react';
import { Link, router } from 'expo-router';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useAuth } from '@/context/AuthContext';

export default function RegisterScreen() {
  const { register } = useAuth();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const onSubmit = async () => {
    setError('');
    if (!fullName || !email || password.length < 8) {
      setError('Name, email, and password (min 8 chars) are required.');
      return;
    }

    setLoading(true);
    try {
      // School/batch can be completed later in profile; keep mobile join lightweight for MVP.
      await register({
        fullName: fullName.trim(),
        email: email.trim(),
        password,
      });
      router.replace('/');
    } catch (e: any) {
      setError(e.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
      <Text style={styles.title}>Join Navodayan</Text>
      <Text style={styles.subtitle}>Create your account to explore the community directory.</Text>

      {!!error && <Text style={styles.error}>{error}</Text>}

      <TextInput
        style={styles.input}
        placeholder="Full name"
        value={fullName}
        onChangeText={setFullName}
      />
      <TextInput
        style={styles.input}
        autoCapitalize="none"
        keyboardType="email-address"
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
      />
      <TextInput
        style={styles.input}
        secureTextEntry
        placeholder="Password (min 8 characters)"
        value={password}
        onChangeText={setPassword}
      />

      <Pressable style={styles.button} onPress={onSubmit} disabled={loading}>
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Create account</Text>
        )}
      </Pressable>

      <Link href="/login" style={styles.link}>
        Already a member? Login
      </Link>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 24, gap: 12 },
  title: { fontSize: 28, fontWeight: '800', color: '#111827', marginTop: 12 },
  subtitle: { fontSize: 15, color: '#6b7280', marginBottom: 8 },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
  },
  button: {
    backgroundColor: '#2563eb',
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 8,
  },
  buttonText: { color: '#fff', fontWeight: '700', fontSize: 16 },
  error: {
    color: '#dc2626',
    backgroundColor: '#fef2f2',
    padding: 10,
    borderRadius: 10,
  },
  link: { marginTop: 16, color: '#2563eb', fontWeight: '600', textAlign: 'center' },
});
