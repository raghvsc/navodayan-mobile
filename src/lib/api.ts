const API_URL = process.env.EXPO_PUBLIC_API_BASE_URL || 'http://127.0.0.1:5000/api';

type RequestOptions = {
  method?: string;
  body?: unknown;
  token?: string | null;
};

class ApiClient {
  private async request(endpoint: string, options: RequestOptions = {}) {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (options.token) {
      headers.Authorization = `Bearer ${options.token}`;
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
      method: options.method || 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(data.message || data.error || 'Something went wrong');
    }

    return data;
  }

  get(endpoint: string, token?: string | null) {
    return this.request(endpoint, { method: 'GET', token });
  }

  post(endpoint: string, body: unknown, token?: string | null) {
    return this.request(endpoint, { method: 'POST', body, token });
  }

  put(endpoint: string, body: unknown, token?: string | null) {
    return this.request(endpoint, { method: 'PUT', body, token });
  }
}

export const api = new ApiClient();
export const apiBaseUrl = API_URL;
