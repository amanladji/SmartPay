import { useState } from 'react';
import api from '../api/axios';
import { useAuth } from '../context/AuthContext';
import { QRCodeSVG } from 'qrcode.react';
import { Send, QrCode, ShieldCheck, Eye, EyeOff, X } from 'lucide-react';
import toast from 'react-hot-toast';

export default function QRPayment() {
  const { user, pinSet } = useAuth();
  const [tab, setTab] = useState('generate');
  const [qrAmount, setQrAmount] = useState('');
  const [payForm, setPayForm] = useState({ receiverUpiId: '', amount: '' });
  const [loading, setLoading] = useState(false);
  const [showPinDialog, setShowPinDialog] = useState(false);
  const [upiPin, setUpiPin] = useState('');
  const [showPin, setShowPin] = useState(false);
  const [pinLoading, setPinLoading] = useState(false);

  const qrPayload = user?.upiId && qrAmount
    ? `upi://pay?pa=${user.upiId}&am=${qrAmount}&tn=SmartPay`
    : null;

  const handlePay = async (e) => {
    e.preventDefault();
    if (payForm.receiverUpiId === user?.upiId) {
      toast.error('Cannot pay yourself', { className: 'toast-error' });
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
        receiverUpiId: payForm.receiverUpiId,
        amount: parseFloat(payForm.amount),
        description: 'QR Payment',
        upiPin: upiPin,
      });
      toast.success(`₹${payForm.amount} paid to ${payForm.receiverUpiId}`, { className: 'toast-success' });
      setPayForm({ receiverUpiId: '', amount: '' });
      setShowPinDialog(false);
      setUpiPin('');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Payment failed', { className: 'toast-error' });
    } finally {
      setPinLoading(false);
    }
  };

  return (
    <div className="fade-in" style={{ maxWidth: 520, margin: '0 auto' }}>
      <div className="page-header">
        <h1>QR Payments</h1>
        <p className="body-text" style={{ color: 'var(--color-ash)' }}>Generate or scan to pay</p>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        <button
          onClick={() => setTab('generate')}
          className={`ghost-pill ${tab === 'generate' ? 'ghost-pill--solid' : 'ghost-pill--dark'}`}
          style={{ fontSize: 14, padding: '8px 20px' }}
        >
          <QrCode size={16} /> Generate QR
        </button>
        <button
          onClick={() => setTab('pay')}
          className={`ghost-pill ${tab === 'pay' ? 'ghost-pill--solid' : 'ghost-pill--dark'}`}
          style={{ fontSize: 14, padding: '8px 20px' }}
        >
          <Send size={16} /> Pay via QR
        </button>
      </div>

      {tab === 'generate' ? (
        <div className="card" style={{ border: '1px solid var(--color-fog)', textAlign: 'center' }}>
          <p className="subheading" style={{ marginBottom: 16 }}>Generate Payment QR</p>
          <div style={{ marginBottom: 20 }}>
            <label className="form-label">Amount (₹)</label>
            <input
              className="form-input"
              type="number"
              step="0.01"
              value={qrAmount}
              onChange={(e) => setQrAmount(e.target.value)}
              placeholder="Enter amount to receive"
            />
          </div>
          {qrPayload && (
            <div style={{
              display: 'inline-block',
              padding: 24,
              background: 'var(--color-snow)',
              borderRadius: 'var(--radius-cards)',
              border: '2px solid var(--color-midnight)',
            }}>
              <QRCodeSVG value={qrPayload} size={200} />
            </div>
          )}
          {qrPayload && (
            <p className="body-small" style={{ color: 'var(--color-ash)', marginTop: 16, wordBreak: 'break-all' }}>
              {qrPayload}
            </p>
          )}
        </div>
      ) : (
        <div className="card" style={{ border: '1px solid var(--color-fog)' }}>
          <p className="subheading" style={{ marginBottom: 20 }}>Pay via QR</p>
          <form onSubmit={handlePay}>
            <div style={{ marginBottom: 20 }}>
              <label className="form-label">Receiver UPI ID</label>
              <input
                className="form-input"
                value={payForm.receiverUpiId}
                onChange={(e) => setPayForm({ ...payForm, receiverUpiId: e.target.value })}
                placeholder="username@smartpay"
                required
              />
            </div>
            <div style={{ marginBottom: 28 }}>
              <label className="form-label">Amount (₹)</label>
              <input
                className="form-input"
                type="number"
                step="0.01"
                min="0.01"
                value={payForm.amount}
                onChange={(e) => setPayForm({ ...payForm, amount: e.target.value })}
                placeholder="0.00"
                required
              />
            </div>
            <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '14px 33px' }} disabled={loading}>
              {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Pay Now'}
            </button>
          </form>
        </div>
      )}

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
              Paying ₹{Number(payForm.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })} to {payForm.receiverUpiId}
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
