import { createContext, useContext, useState, useEffect } from 'react';
import api from '../api/axios';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);
  const [pinSet, setPinSet] = useState(false);

  useEffect(() => {
    if (token) {
      api.get('/users/me')
        .then((res) => {
          setUser(res.data.data);
          setPinSet(res.data.data.pinSet);
        })
        .catch(() => {
          localStorage.removeItem('token');
          localStorage.removeItem('refreshToken');
          setToken(null);
          setUser(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, [token]);

  const storeTokens = (data) => {
    localStorage.setItem('token', data.token);
    if (data.refreshToken) localStorage.setItem('refreshToken', data.refreshToken);
    setToken(data.token);
    setPinSet(data.pinSet);
  };

  const login = async (email, password, deviceId, deviceName) => {
    const res = await api.post('/auth/login', { email, password, deviceId, deviceName });
    const data = res.data.data;
    if (data.requiresOtp) {
      return data;
    }
    storeTokens(data);
    const userRes = await api.get('/users/me');
    setUser(userRes.data.data);
    return data;
  };

  const verifyOtp = async (email, otp, deviceId, deviceName) => {
    const res = await api.post('/auth/verify-otp', { email, otp, deviceId, deviceName });
    storeTokens(res.data.data);
    const userRes = await api.get('/users/me');
    setUser(userRes.data.data);
    return res.data;
  };

  const register = async (name, email, phone, password, deviceId, deviceName) => {
    const res = await api.post('/auth/register', { name, email, phone, password, deviceId, deviceName });
    storeTokens(res.data.data);
    const userRes = await api.get('/users/me');
    setUser(userRes.data.data);
    return res.data;
  };

  const refreshPinStatus = async () => {
    try {
      const res = await api.get('/users/me');
      setPinSet(res.data.data.pinSet);
    } catch {}
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, register, logout, pinSet, refreshPinStatus, verifyOtp }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
