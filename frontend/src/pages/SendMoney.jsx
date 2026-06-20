import { useState } from 'react';
import api from '../api/axios';
import { useAuth } from '../context/AuthContext';
import { Send, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';

export default function SendMoney() {
  const { user } = useAuth();
  const [form, setForm] = useState({ receiverUpiId: '', amount: '', description: '' });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (form.receiverUpiId === user?.upiId) {
      toast.error('Cannot send money to yourself', { className: 'toast-error' });
      return;
    }
    setLoading(true);
    try {
      const res = await api.post('/payments/transfer', {
        receiverUpiId: form.receiverUpiId,
        amount: parseFloat(form.amount),
        description: form.description || 'Payment',
      });
      setSuccess(res.data.data);
      toast.success('Payment sent successfully!', { className: 'toast-success' });
    } catch (err) {
      toast.error(err.response?.data?.message || 'Transfer failed', { className: 'toast-error' });
    } finally {
      setLoading(false);
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
    </div>
  );
}
