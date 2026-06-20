import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../api/axios';
import { Send, Plus, ArrowUp, ArrowDown } from 'lucide-react';
import LoadingSpinner from '../components/LoadingSpinner';

export default function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [wallet, setWallet] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get('/wallet/balance'),
      api.get('/transactions?page=0&size=5'),
      api.get('/transactions/stats'),
    ]).then(([walletRes, txnRes, statsRes]) => {
      setWallet(walletRes.data.data);
      setTransactions(txnRes.data.data.content);
      setStats(statsRes.data.data);
    }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  if (loading) return <LoadingSpinner />;

  const txnTypeIcon = (type) => type === 'CREDIT'
    ? <ArrowDown size={14} style={{ color: 'var(--color-success)' }} />
    : <ArrowUp size={14} style={{ color: 'var(--color-error)' }} />;

  return (
    <div className="fade-in">
      <div className="page-header">
        <p className="body-text" style={{ color: 'var(--color-ash)', marginBottom: 4 }}>Welcome back,</p>
        <h1>{user?.name || 'User'}</h1>
        <p className="body-small" style={{ color: 'var(--color-ash)', marginTop: 4 }}>
          UPI ID: <strong style={{ color: 'var(--color-midnight)' }}>{wallet?.upiId || '—'}</strong>
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginBottom: 48 }}>
        <div className="card--navy card" style={{ padding: 32, borderRadius: 'var(--radius-cards)' }}>
          <p className="body-small" style={{ opacity: 0.7, marginBottom: 8 }}>Wallet Balance</p>
          <p className="heading-display" style={{ fontSize: 48, letterSpacing: '-1.44px' }}>
            ₹{wallet?.balance?.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
          </p>
          <div style={{ display: 'flex', gap: 12, marginTop: 24 }}>
            <button className="ghost-pill ghost-pill--light" onClick={() => navigate('/send')} style={{ fontSize: 14, padding: '10px 24px' }}>
              <Send size={16} /> Send Money
            </button>
            <button className="ghost-pill ghost-pill--light" onClick={() => navigate('/wallet')} style={{ fontSize: 14, padding: '10px 24px' }}>
              <Plus size={16} /> Add Money
            </button>
          </div>
        </div>

        <div className="card" style={{ border: '1px solid var(--color-fog)' }}>
          <p className="subheading" style={{ marginBottom: 20 }}>Monthly Summary</p>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <div>
              <p className="body-small" style={{ color: 'var(--color-ash)' }}>Total Sent</p>
              <p style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 24, color: 'var(--color-error)' }}>
                ₹{(stats?.totalSent || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
              </p>
            </div>
            <div>
              <p className="body-small" style={{ color: 'var(--color-ash)' }}>Total Received</p>
              <p style={{ fontFamily: 'var(--font-display)', fontWeight: 900, fontSize: 24, color: 'var(--color-success)' }}>
                ₹{(stats?.totalReceived || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
              </p>
            </div>
          </div>
          <div style={{ marginTop: 16, display: 'flex', gap: 16 }}>
            <div>
              <p className="body-small" style={{ color: 'var(--color-ash)' }}>Transactions</p>
              <p style={{ fontWeight: 700, fontSize: 18 }}>{(stats?.sentCount || 0) + (stats?.receivedCount || 0)} total</p>
            </div>
          </div>
        </div>
      </div>

      <div>
        <h2 className="subheading" style={{ marginBottom: 16 }}>Recent Transactions</h2>
        {transactions.length === 0 ? (
          <div className="card" style={{ border: '1px solid var(--color-fog)', textAlign: 'center', padding: 48 }}>
            <p className="body-text" style={{ color: 'var(--color-ash)' }}>No transactions yet</p>
            <button className="ghost-pill ghost-pill--dark" onClick={() => navigate('/send')} style={{ marginTop: 16, fontSize: 14, padding: '10px 24px' }}>
              Send your first payment
            </button>
          </div>
        ) : (
          <div className="card" style={{ border: '1px solid var(--color-fog)', padding: 0, overflow: 'hidden' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>From / To</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {transactions.map((txn) => (
                  <tr key={txn.id}>
                    <td>{txnTypeIcon(txn.type)} {txn.type}</td>
                    <td className="body-small">
                      {txn.type === 'DEBIT' ? txn.receiverUpiId : txn.senderUpiId}
                    </td>
                    <td style={{ fontWeight: 600, color: txn.type === 'CREDIT' ? 'var(--color-success)' : 'var(--color-error)' }}>
                      {txn.type === 'CREDIT' ? '+' : '-'}₹{Number(txn.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </td>
                    <td>
                      <span className={`badge badge--${txn.status.toLowerCase()}`}>{txn.status}</span>
                    </td>
                    <td className="body-small" style={{ color: 'var(--color-ash)' }}>
                      {new Date(txn.createdAt).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
