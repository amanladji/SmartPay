import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { ShieldCheck } from 'lucide-react';
import toast from 'react-hot-toast';

export default function OtpVerification() {
  const { state } = useLocation();
  const { verifyOtp } = useAuth();
  const navigate = useNavigate();
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);

  if (!state?.email) {
    navigate('/login');
    return null;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (otp.length !== 6) {
      toast.error('OTP must be 6 digits', { className: 'toast-error' });
      return;
    }
    setLoading(true);
    try {
      await verifyOtp(state.email, otp, state.deviceId, state.deviceName);
      toast.success('Login successful!', { className: 'toast-success' });
      navigate('/');
    } catch (err) {
      toast.error(err.response?.data?.message || 'OTP verification failed', { className: 'toast-error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="section-sky" style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div className="card fade-in" style={{ width: '100%', maxWidth: 420, padding: 48 }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 64, height: 64, borderRadius: '50%',
            background: 'var(--color-cerulean-surge)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 16px',
          }}>
            <ShieldCheck size={32} style={{ color: 'var(--color-midnight)' }} />
          </div>
          <h1 className="heading-large" style={{ fontSize: 28 }}>Verify OTP</h1>
          <p className="body-text" style={{ color: 'var(--color-ash)', marginTop: 8 }}>
            Enter the 6-digit code sent to your registered phone number
          </p>
          {state.otp && (
            <div style={{
              marginTop: 20, padding: '12px 16px', borderRadius: 8,
              background: '#e8f5e9', border: '1px solid #c8e6c9',
              fontSize: 14, color: '#2e7d32', textAlign: 'center'
            }}>
              📱 OTP <strong>{state.otp}</strong> sent to your registered phone
              <div style={{ fontSize: 12, marginTop: 4, opacity: 0.7 }}>
                (Simulated — no real SMS gateway. In production, this arrives via SMS on your phone.)
              </div>
            </div>
          )}
        </div>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 28 }}>
            <input
              className="form-input"
              type="text"
              inputMode="numeric"
              pattern="[0-9]*"
              maxLength={6}
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
              placeholder="Enter 6-digit OTP"
              style={{ fontSize: 28, letterSpacing: 12, textAlign: 'center' }}
              autoFocus
              required
            />
          </div>
          <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '16px 33px', fontSize: 16 }} disabled={loading}>
            {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Verify OTP'}
          </button>
        </form>
      </div>
    </div>
  );
}
