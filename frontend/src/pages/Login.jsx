import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await login(email, password);
      toast.success('Welcome back!', { className: 'toast-success' });
      navigate('/');
    } catch (err) {
      const msg = err.response?.data?.message || err.message || 'Login failed';
      toast.error(msg, { className: 'toast-error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="section-sky" style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div className="card fade-in" style={{ width: '100%', maxWidth: 420, padding: 48 }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{ fontSize: 40, marginBottom: 8 }}>✦</div>
          <h1 className="heading-large" style={{ fontSize: 32 }}>SmartPay</h1>
          <p className="body-text" style={{ color: 'var(--color-ash)', marginTop: 8 }}>Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 20 }}>
            <label className="form-label">Email</label>
            <input
              className="form-input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
            />
          </div>
          <div style={{ marginBottom: 28 }}>
            <label className="form-label">Password</label>
            <input
              className="form-input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
            />
          </div>
          <button
            type="submit"
            className="ghost-pill ghost-pill--solid"
            style={{ width: '100%', padding: '16px 33px', fontSize: 16 }}
            disabled={loading}
          >
            {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Sign In'}
          </button>
        </form>

        <p className="body-text" style={{ textAlign: 'center', marginTop: 24, color: 'var(--color-ash)' }}>
          Don't have an account?{' '}
          <Link to="/register" style={{ color: 'var(--color-midnight)', fontWeight: 600, textDecoration: 'underline' }}>
            Create one
          </Link>
        </p>
      </div>
    </div>
  );
}
