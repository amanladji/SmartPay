import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck, Eye, EyeOff } from 'lucide-react';
import toast from 'react-hot-toast';

export default function SetUpiPin() {
  const { user, refreshPinStatus } = useAuth();
  const navigate = useNavigate();
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [showPin, setShowPin] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (pin !== confirmPin) {
      toast.error('PINs do not match', { className: 'toast-error' });
      return;
    }
    if (pin.length < 4 || pin.length > 6) {
      toast.error('PIN must be 4 to 6 digits', { className: 'toast-error' });
      return;
    }
    setLoading(true);
    try {
      await api.post('/users/set-pin', { upiPin: pin });
      toast.success('UPI PIN set successfully!', { className: 'toast-success' });
      await refreshPinStatus();
      navigate('/');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to set PIN', { className: 'toast-error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fade-in" style={{ maxWidth: 440, margin: '0 auto', paddingTop: 48 }}>
      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <div style={{
          width: 72, height: 72, borderRadius: '50%',
          background: 'var(--color-cerulean-surge)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 16px',
        }}>
          <ShieldCheck size={36} style={{ color: 'var(--color-midnight)' }} />
        </div>
        <h1 className="heading-large" style={{ fontSize: 28 }}>Set UPI PIN</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)', marginTop: 8 }}>
          {user?.name}, set a secure 4-6 digit PIN for transactions
        </p>
      </div>

      <form onSubmit={handleSubmit} className="card" style={{ border: '1px solid var(--color-fog)' }}>
        <div style={{ marginBottom: 20 }}>
          <label className="form-label">New UPI PIN</label>
          <div style={{ position: 'relative' }}>
            <input
              className="form-input"
              type={showPin ? 'text' : 'password'}
              inputMode="numeric"
              pattern="[0-9]*"
              maxLength={6}
              value={pin}
              onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
              placeholder="Enter 4-6 digit PIN"
              required
            />
            <button type="button" onClick={() => setShowPin(!showPin)} style={{
              position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
              background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ash)',
            }}>
              {showPin ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>
        </div>
        <div style={{ marginBottom: 28 }}>
          <label className="form-label">Confirm UPI PIN</label>
          <input
            className="form-input"
            type={showPin ? 'text' : 'password'}
            inputMode="numeric"
            pattern="[0-9]*"
            maxLength={6}
            value={confirmPin}
            onChange={(e) => setConfirmPin(e.target.value.replace(/\D/g, ''))}
            placeholder="Re-enter PIN"
            required
          />
        </div>
        <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '16px 33px', fontSize: 16 }} disabled={loading}>
          {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Set PIN'}
        </button>
      </form>
    </div>
  );
}
