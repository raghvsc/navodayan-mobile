import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { api } from '@/lib/api';
import { useAuth } from '@/context/AuthContext';

type Profile = {
  id: string;
  fullName: string;
  currentRole?: string;
  company?: string;
  location?: string;
  openToMentor?: boolean;
};

export default function DirectoryScreen() {
  const { token, user } = useAuth();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const timer = setTimeout(async () => {
      setLoading(true);
      setError('');
      try {
        const params = new URLSearchParams({ page: '1', limit: '20' });
        if (user && search.trim()) params.append('search', search.trim());
        const res = await api.get(`/directory/search?${params.toString()}`, token);
        setProfiles(res.data || []);
      } catch (e: any) {
        setError(e.message || 'Failed to load directory');
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [search, token, user]);

  return (
    <View style={styles.container}>
      {user ? (
        <TextInput
          style={styles.search}
          placeholder="Search by name, role, company..."
          value={search}
          onChangeText={setSearch}
        />
      ) : (
        <Text style={styles.hint}>Sign in to search and filter. Showing default directory list.</Text>
      )}

      {loading && (
        <View style={styles.center}>
          <ActivityIndicator size="large" color="#2563eb" />
        </View>
      )}

      {!loading && !!error && <Text style={styles.error}>{error}</Text>}

      {!loading && !error && (
        <FlatList
          data={profiles}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ paddingBottom: 24, gap: 10 }}
          ListEmptyComponent={<Text style={styles.hint}>No Navodayans found.</Text>}
          renderItem={({ item }) => (
            <View style={styles.card}>
              <Text style={styles.name}>{item.fullName}</Text>
              {!!item.currentRole && <Text style={styles.meta}>{item.currentRole}</Text>}
              {!!item.company && <Text style={styles.meta}>{item.company}</Text>}
              {!!item.location && <Text style={styles.meta}>{item.location}</Text>}
              {item.openToMentor && <Text style={styles.badge}>Open to mentor</Text>}
            </View>
          )}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  search: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 12,
    fontSize: 16,
  },
  hint: { color: '#6b7280', marginBottom: 12 },
  center: { paddingTop: 40, alignItems: 'center' },
  error: { color: '#dc2626', marginTop: 12 },
  card: {
    backgroundColor: '#fff',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#e5e7eb',
    padding: 14,
    gap: 4,
  },
  name: { fontSize: 17, fontWeight: '700', color: '#111827' },
  meta: { fontSize: 14, color: '#6b7280' },
  badge: {
    marginTop: 6,
    alignSelf: 'flex-start',
    backgroundColor: '#eff6ff',
    color: '#1d4ed8',
    fontWeight: '700',
    fontSize: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
    overflow: 'hidden',
  },
});
