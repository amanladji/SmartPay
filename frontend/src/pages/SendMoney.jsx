import { useState } from 'react';
import api from '../api/axios';
import { useAuth } from '../context/AuthContext';
import { Send, CheckCircle, ShieldCheck, Eye, EyeOff, X } from 'lucide-react';
import toast from 'react-hot-toast';

export default function SendMoney() {
  const { user, pinSet } = useAuth();
  const [form, setForm] = useState({ receiverUpiId: '', amount: '', description: '' });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(null);
  const [showPinDialog, setShowPinDialog] = useState(false);
  const [upiPin, setUpiPin] = useState('');
  const [showPin, setShowPin] = useState(false);
  const [pinLoading, setPinLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (form.receiverUpiId === user?.upiId) {
      toast.error('Cannot send money to yourself', { className: 'toast-error' });
      return;
    }
    if (!pinSet) {
      toast.error('Please set your UPI PIN first from Profile', { className: 'toast-error' });
      return;
    }
    setShowPinDialog(true);
  };

  const handlePinSubmit = async () => {
    if (!upiPin || upiPin.length < 4) {
      toast.error('Enter a valid 4-6 digit PIN', { className: 'toast-error' });
      return;
    }
    setPinLoading(true);
    try {
      const res = await api.post('/payments/transfer', {
        receiverUpiId: form.receiverUpiId,
        amount: parseFloat(form.amount),
        description: form.description || 'Payment',
        upiPin: upiPin,
      });
      setSuccess(res.data.data);
      setShowPinDialog(false);
      setUpiPin('');
      toast.success('Payment sent successfully!', { className: 'toast-success' });
    } catch (err) {
      toast.error(err.response?.data?.message || 'Transfer failed', { className: 'toast-error' });
    } finally {
      setPinLoading(false);
    }
  };

  if (success) {
    return (
      <div className="fade-in" style={{ maxWidth: 480, margin: '0 auto', textAlign: 'center', paddingTop: 64 }}>
        <div style={{ fontSize: 64, color: 'var(--color-success)', marginBottom: 16 }}>
          <CheckCircle size={64} />
        </div>
        <h1 className="heading-large" style={{ fontSize: 28, marginBottom: 8 }}>Payment Successful!</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)', marginBottom: 24 }}>
          ₹{Number(success.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })} sent to {success.receiverUpiId}
        </p>
        <div className="card" style={{ border: '1px solid var(--color-fog)', marginBottom: 24, textAlign: 'left' }}>
          <div style={{ marginBottom: 12 }}>
            <span className="body-small" style={{ color: 'var(--color-ash)' }}>Reference ID</span>
            <p className="body-text" style={{ fontWeight: 600, wordBreak: 'break-all' }}>{success.referenceId}</p>
          </div>
          <div>
            <span className="body-small" style={{ color: 'var(--color-ash)' }}>Date</span>
            <p className="body-text">{new Date(success.createdAt).toLocaleString()}</p>
          </div>
        </div>
        <button className="ghost-pill ghost-pill--dark" onClick={() => { setSuccess(null); setForm({ receiverUpiId: '', amount: '', description: '' }); }}>
          Send Another Payment
        </button>
      </div>
    );
  }

  return (
    <div className="fade-in" style={{ maxWidth: 520, margin: '0 auto' }}>
      <div className="page-header">
        <h1>Send Money</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)' }}>Transfer money to any SmartPay UPI ID</p>
      </div>

      <div className="card section-sky" style={{ marginBottom: 24 }}>
        <p className="body-small" style={{ opacity: 0.7 }}>Your Balance</p>
        <p className="heading-large" style={{ fontSize: 32, marginTop: 4 }}>₹{/* We'll fetch this on mount */}</p>
      </div>

      <form onSubmit={handleSubmit} className="card" style={{ border: '1px solid var(--color-fog)' }}>
        <div style={{ marginBottom: 20 }}>
          <label className="form-label">Receiver UPI ID</label>
          <input
            className="form-input"
            value={form.receiverUpiId}
            onChange={(e) => setForm({ ...form, receiverUpiId: e.target.value })}
            placeholder="username@smartpay"
            required
          />
        </div>
        <div style={{ marginBottom: 20 }}>
          <label className="form-label">Amount (₹)</label>
          <input
            className="form-input"
            type="number"
            step="0.01"
            min="0.01"
            value={form.amount}
            onChange={(e) => setForm({ ...form, amount: e.target.value })}
            placeholder="0.00"
            required
          />
        </div>
        <div style={{ marginBottom: 28 }}>
          <label className="form-label">Description (optional)</label>
          <input
            className="form-input"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
            placeholder="What's this for?"
          />
        </div>

        <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '16px 33px', fontSize: 16 }} disabled={loading}>
          {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : <><Send size={18} /> Send ₹{form.amount || '0'}</>}
        </button>
      </form>

      {showPinDialog && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          zIndex: 1000, padding: 16,
        }} onClick={() => { setShowPinDialog(false); setUpiPin(''); }}>
          <div className="card fade-in" style={{ maxWidth: 380, width: '100%', padding: 32 }} onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <ShieldCheck size={20} style={{ color: 'var(--color-midnight)' }} />
                <span className="subheading">Enter UPI PIN</span>
              </div>
              <button onClick={() => { setShowPinDialog(false); setUpiPin(''); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ash)' }}>
                <X size={20} />
              </button>
            </div>
            <p className="body-small" style={{ color: 'var(--color-ash)', marginBottom: 16 }}>
              Paying ₹{Number(form.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })} to {form.receiverUpiId}
            </p>
            <div style={{ marginBottom: 20, position: 'relative' }}>
              <input
                className="form-input"
                type={showPin ? 'text' : 'password'}
                inputMode="numeric"
                pattern="[0-9]*"
                maxLength={6}
                value={upiPin}
                onChange={(e) => setUpiPin(e.target.value.replace(/\D/g, ''))}
                placeholder="Enter your UPI PIN"
                style={{ fontSize: 24, letterSpacing: 8, textAlign: 'center' }}
                autoFocus
              />
              <button type="button" onClick={() => setShowPin(!showPin)} style={{
                position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
                background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ash)',
              }}>
                {showPin ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            <button className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '14px', fontSize: 15 }} disabled={pinLoading} onClick={handlePinSubmit}>
              {pinLoading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Pay Now'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
