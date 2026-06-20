import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div style={{ textAlign: 'center', padding: '120px 24px' }}>
      <p className="heading-display" style={{ fontSize: 120 }}>404</p>
      <h1 className="heading-large" style={{ fontSize: 28, marginBottom: 16 }}>Page not found</h1>
      <p className="body-text" style={{ color: 'var(--color-ash)', marginBottom: 32 }}>
        The page you're looking for doesn't exist or has been moved.
      </p>
      <Link to="/" className="ghost-pill ghost-pill--dark">
        Go Home
      </Link>
    </div>
  );
}
