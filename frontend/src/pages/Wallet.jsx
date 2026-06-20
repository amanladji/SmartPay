import { useState, useEffect } from 'react';
import api from '../api/axios';
import { Plus, Wallet as WalletIcon } from 'lucide-react';
import toast from 'react-hot-toast';
import LoadingSpinner from '../components/LoadingSpinner';

export default function WalletPage() {
  const [wallet, setWallet] = useState(null);
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(true);
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    api.get('/wallet/balance')
      .then((res) => setWallet(res.data.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleAddMoney = async (e) => {
    e.preventDefault();
    setAdding(true);
    try {
      const res = await api.post('/wallet/add', { amount: parseFloat(amount) });
      setWallet(res.data.data);
      toast.success(`₹${Number(amount).toLocaleString('en-IN')} added to wallet!`, { className: 'toast-success' });
      setAmount('');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to add money', { className: 'toast-error' });
    } finally {
      setAdding(false);
    }
  };

  if (loading) return <LoadingSpinner />;

  return (
    <div className="fade-in">
      <div className="page-header">
        <h1>Wallet</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)' }}>Manage your SmartPay wallet</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        <div className="card--navy card" style={{ padding: 32, borderRadius: 'var(--radius-cards)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
            <WalletIcon size={24} />
            <span className="subheading">Current Balance</span>
          </div>
          <p className="heading-display" style={{ fontSize: 56, letterSpacing: '-1.68px' }}>
            ₹{wallet?.balance?.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
          </p>
          <p className="body-small" style={{ opacity: 0.7, marginTop: 8 }}>
            UPI ID: {wallet?.upiId}
          </p>
        </div>

        <div className="card" style={{ border: '1px solid var(--color-fog)' }}>
          <h2 className="subheading" style={{ marginBottom: 20 }}>Add Money</h2>
          <p className="body-small" style={{ color: 'var(--color-ash)', marginBottom: 16 }}>
            Simulate adding funds from your bank account
          </p>
          <form onSubmit={handleAddMoney}>
            <div style={{ marginBottom: 20 }}>
              <label className="form-label">Amount (₹)</label>
              <input
                className="form-input"
                type="number"
                step="1"
                min="1"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="Enter amount"
                required
              />
            </div>
            <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '14px 33px' }} disabled={adding}>
              {adding ? <div className="spinner" style={{ width: 20, height: 20 }} /> : <><Plus size={18} /> Add to Wallet</>}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
