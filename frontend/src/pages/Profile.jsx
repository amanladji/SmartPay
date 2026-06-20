import { useAuth } from '../context/AuthContext';
import { User, Mail, Phone, CreditCard, Calendar } from 'lucide-react';

export default function Profile() {
  const { user } = useAuth();

  const details = [
    { icon: User, label: 'Name', value: user?.name },
    { icon: Mail, label: 'Email', value: user?.email },
    { icon: Phone, label: 'Phone', value: user?.phone },
    { icon: CreditCard, label: 'UPI ID', value: user?.upiId },
    { icon: Calendar, label: 'Member Since', value: user?.createdAt ? new Date(user.createdAt).toLocaleDateString() : '—' },
  ];

  return (
    <div className="fade-in" style={{ maxWidth: 600, margin: '0 auto' }}>
      <div className="page-header" style={{ textAlign: 'center' }}>
        <div style={{
          width: 80, height: 80, borderRadius: 'var(--radius-avatars)',
          background: 'var(--color-cerulean-surge)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 32, fontWeight: 900, margin: '0 auto 16px',
        }}>
          {user?.name?.charAt(0) || 'U'}
        </div>
        <h1>{user?.name || 'User'}</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)' }}>{user?.upiId}</p>
      </div>

      <div className="card" style={{ border: '1px solid var(--color-fog)' }}>
        {details.map((item, idx) => {
          const Icon = item.icon;
          return (
            <div key={idx} style={{
              display: 'flex', alignItems: 'center', gap: 16,
              padding: '16px 0',
              borderBottom: idx < details.length - 1 ? '1px solid var(--color-fog)' : 'none',
            }}>
              <Icon size={20} style={{ color: 'var(--color-ash)', flexShrink: 0 }} />
              <div>
                <p className="body-small" style={{ color: 'var(--color-ash)' }}>{item.label}</p>
                <p className="body-text" style={{ fontWeight: 500 }}>{item.value || '—'}</p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
