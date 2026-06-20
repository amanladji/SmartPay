import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

export default function Register() {
  const [form, setForm] = useState({ name: '', email: '', phone: '', password: '', confirmPassword: '' });
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (form.password !== form.confirmPassword) {
      toast.error('Passwords do not match', { className: 'toast-error' });
      return;
    }
    if (!/^\d{10}$/.test(form.phone)) {
      toast.error('Phone must be exactly 10 digits', { className: 'toast-error' });
      return;
    }
    setLoading(true);
    try {
      const res = await register(form.name, form.email, form.phone, form.password);
      toast.success(res.message || 'Registration successful!', { className: 'toast-success' });
      navigate('/');
    } catch (err) {
      const msg = err.response?.data?.message || err.message || 'Registration failed';
      toast.error(msg, { className: 'toast-error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="section-sky" style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 }}>
      <div className="card fade-in" style={{ width: '100%', maxWidth: 460, padding: 48 }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{ fontSize: 40, marginBottom: 8 }}>✦</div>
          <h1 className="heading-large" style={{ fontSize: 32 }}>Get Started</h1>
          <p className="body-text" style={{ color: 'var(--color-ash)', marginTop: 8 }}>Create your SmartPay account</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label className="form-label">Full Name</label>
            <input className="form-input" name="name" value={form.name} onChange={handleChange} placeholder="John Doe" required />
          </div>
          <div style={{ marginBottom: 16 }}>
            <label className="form-label">Email</label>
            <input className="form-input" type="email" name="email" value={form.email} onChange={handleChange} placeholder="you@example.com" required />
          </div>
          <div style={{ marginBottom: 16 }}>
            <label className="form-label">Phone</label>
            <input className="form-input" type="tel" name="phone" value={form.phone} onChange={handleChange} placeholder="9876543210" required />
          </div>
          <div style={{ marginBottom: 16 }}>
            <label className="form-label">Password</label>
            <input className="form-input" type="password" name="password" value={form.password} onChange={handleChange} placeholder="Min 6 characters" required minLength={6} />
          </div>
          <div style={{ marginBottom: 28 }}>
            <label className="form-label">Confirm Password</label>
            <input className="form-input" type="password" name="confirmPassword" value={form.confirmPassword} onChange={handleChange} placeholder="Repeat password" required />
          </div>
          <button type="submit" className="ghost-pill ghost-pill--solid" style={{ width: '100%', padding: '16px 33px', fontSize: 16 }} disabled={loading}>
            {loading ? <div className="spinner" style={{ width: 20, height: 20 }} /> : 'Create Account'}
          </button>
        </form>

        <p className="body-text" style={{ textAlign: 'center', marginTop: 24, color: 'var(--color-ash)' }}>
          Already have an account?{' '}
          <Link to="/login" style={{ color: 'var(--color-midnight)', fontWeight: 600, textDecoration: 'underline' }}>
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
