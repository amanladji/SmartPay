import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Wallet, Send, ArrowLeftRight, User, LogOut, Menu, X, QrCode } from 'lucide-react';
import { useState } from 'react';
import './Navbar.css';

export default function Navbar() {
  const { user, logout } = useAuth();
  const location = useLocation();
  const [menuOpen, setMenuOpen] = useState(false);

  const links = [
    { to: '/', icon: Wallet, label: 'Dashboard' },
    { to: '/send', icon: Send, label: 'Send Money' },
    { to: '/transactions', icon: ArrowLeftRight, label: 'Transactions' },
    { to: '/wallet', icon: Wallet, label: 'Wallet' },
    { to: '/qr', icon: QrCode, label: 'QR Pay' },
  ];

  return (
    <nav className="navbar">
      <div className="navbar-inner page-container">
        <Link to="/" className="navbar-brand">
          <span className="brand-icon">✦</span>
          <span className="brand-text">SmartPay</span>
        </Link>

        <div className={`navbar-links ${menuOpen ? 'open' : ''}`}>
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = location.pathname === link.to;
            return (
              <Link
                key={link.to}
                to={link.to}
                className={`nav-link ${isActive ? 'active' : ''}`}
                onClick={() => setMenuOpen(false)}
              >
                <Icon size={16} />
                <span>{link.label}</span>
              </Link>
            );
          })}
        </div>

        <div className="navbar-right">
          <Link to="/profile" className="nav-user">
            <div className="nav-avatar">{user?.name?.charAt(0) || 'U'}</div>
            <span className="nav-username">{user?.name || 'User'}</span>
          </Link>
          <button className="ghost-pill ghost-pill--dark nav-logout" onClick={logout}>
            <LogOut size={16} />
            <span>Logout</span>
          </button>
          <button className="mobile-menu-btn" onClick={() => setMenuOpen(!menuOpen)}>
            {menuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>
    </nav>
  );
}
