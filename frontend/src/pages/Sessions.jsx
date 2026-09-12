import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Smartphone, Monitor, Trash2, LogOut } from 'lucide-react';
import toast from 'react-hot-toast';
import LoadingSpinner from '../components/LoadingSpinner';

export default function Sessions() {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/users/sessions')
      .then((res) => setSessions(res.data.data))
      .catch(() => toast.error('Failed to load sessions', { className: 'toast-error' }))
      .finally(() => setLoading(false));
  }, []);

  const revokeSession = async (deviceId) => {
    try {
      await api.delete(`/users/sessions/${deviceId}`);
      setSessions((prev) => prev.filter((s) => s.deviceId !== deviceId));
      toast.success('Session revoked', { className: 'toast-success' });
    } catch {
      toast.error('Failed to revoke session', { className: 'toast-error' });
    }
  };

  const revokeAll = async () => {
    try {
      await api.delete('/users/sessions');
      setSessions([]);
      toast.success('All sessions revoked', { className: 'toast-success' });
    } catch {
      toast.error('Failed to revoke sessions', { className: 'toast-error' });
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="fade-in" style={{ maxWidth: 640, margin: '0 auto' }}>
      <div className="page-header">
        <h1>Active Sessions</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)' }}>Manage your logged-in devices</p>
      </div>

      {sessions.length > 0 && (
        <button className="ghost-pill ghost-pill--dark" onClick={revokeAll} style={{ marginBottom: 20, fontSize: 13, padding: '8px 16px' }}>
          <LogOut size={14} /> Revoke All Sessions
        </button>
      )}

      {sessions.length === 0 ? (
        <div className="card" style={{ border: '1px solid var(--color-fog)', textAlign: 'center', padding: 48 }}>
          <p className="body-text" style={{ color: 'var(--color-ash)' }}>No active sessions</p>
        </div>
      ) : (
        <div className="card" style={{ border: '1px solid var(--color-fog)', padding: 0, overflow: 'hidden' }}>
          {sessions.map((session, idx) => (
            <div key={session.deviceId} style={{
              display: 'flex', alignItems: 'center', gap: 16,
              padding: '16px 20px',
              borderBottom: idx < sessions.length - 1 ? '1px solid var(--color-fog)' : 'none',
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 8,
                background: 'var(--color-fog)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {session.deviceName?.toLowerCase().includes('mobile') || session.deviceName?.toLowerCase().includes('android') || session.deviceName?.toLowerCase().includes('iphone')
                  ? <Smartphone size={20} style={{ color: 'var(--color-ash)' }} />
                  : <Monitor size={20} style={{ color: 'var(--color-ash)' }} />}
              </div>
              <div style={{ flex: 1 }}>
                <p className="body-text" style={{ fontWeight: 600 }}>{session.deviceName || 'Unknown Device'}</p>
                <p className="body-small" style={{ color: 'var(--color-ash)' }}>
                  {session.trusted ? 'Trusted' : 'Untrusted'} &middot; Last login: {session.lastLogin ? new Date(session.lastLogin).toLocaleString() : '—'}
                </p>
              </div>
              <button className="ghost-pill ghost-pill--dark" onClick={() => revokeSession(session.deviceId)}
                style={{ fontSize: 12, padding: '6px 14px', color: 'var(--color-error)' }}>
                <Trash2 size={13} /> Revoke
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
