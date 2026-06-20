import { useState, useEffect } from 'react';
import api from '../api/axios';
import { ArrowUp, ArrowDown, Filter, ChevronLeft, ChevronRight } from 'lucide-react';
import LoadingSpinner from '../components/LoadingSpinner';

export default function Transactions() {
  const [data, setData] = useState(null);
  const [page, setPage] = useState(0);
  const [typeFilter, setTypeFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const size = 10;

  useEffect(() => {
    setLoading(true);
    const params = new URLSearchParams({ page, size });
    if (typeFilter) params.append('type', typeFilter);

    api.get(`/transactions?${params}`)
      .then((res) => setData(res.data.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [page, typeFilter]);

  const filters = [
    { label: 'All', value: '' },
    { label: 'Credits', value: 'CREDIT' },
    { label: 'Debits', value: 'DEBIT' },
  ];

  return (
    <div className="fade-in">
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 16 }}>
        <div>
          <h1>Transactions</h1>
          <p className="body-text" style={{ color: 'var(--color-ash)' }}>View your payment history</p>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        {filters.map((f) => (
          <button
            key={f.value}
            onClick={() => { setTypeFilter(f.value); setPage(0); }}
            className={`ghost-pill ${typeFilter === f.value ? 'ghost-pill--solid' : 'ghost-pill--dark'}`}
            style={{ fontSize: 14, padding: '8px 20px' }}
          >
            <Filter size={14} />
            {f.label}
          </button>
        ))}
      </div>

      {loading ? <LoadingSpinner /> : !data || data.content.length === 0 ? (
        <div className="card" style={{ border: '1px solid var(--color-fog)', textAlign: 'center', padding: 64 }}>
          <p className="body-text" style={{ color: 'var(--color-ash)' }}>No transactions found</p>
        </div>
      ) : (
        <>
          <div className="card" style={{ border: '1px solid var(--color-fog)', padding: 0, overflow: 'hidden' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Sender</th>
                  <th>Receiver</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Description</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {data.content.map((txn) => (
                  <tr key={txn.id}>
                    <td>
                      {txn.type === 'CREDIT'
                        ? <ArrowDown size={14} style={{ color: 'var(--color-success)' }} />
                        : <ArrowUp size={14} style={{ color: 'var(--color-error)' }} />
                      }
                      {' '}{txn.type}
                    </td>
                    <td className="body-small">{txn.senderUpiId}</td>
                    <td className="body-small">{txn.receiverUpiId}</td>
                    <td style={{ fontWeight: 600, color: txn.type === 'CREDIT' ? 'var(--color-success)' : 'var(--color-error)' }}>
                      {txn.type === 'CREDIT' ? '+' : '-'}₹{Number(txn.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </td>
                    <td>
                      <span className={`badge badge--${txn.status.toLowerCase()}`}>{txn.status}</span>
                    </td>
                    <td className="body-small" style={{ color: 'var(--color-ash)' }}>{txn.description || '—'}</td>
                    <td className="body-small" style={{ color: 'var(--color-ash)' }}>
                      {new Date(txn.createdAt).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 16, marginTop: 24 }}>
            <button
              className="ghost-pill ghost-pill--dark"
              onClick={() => setPage(Math.max(0, page - 1))}
              disabled={page === 0}
              style={{ padding: '8px 20px', fontSize: 14, opacity: page === 0 ? 0.4 : 1 }}
            >
              <ChevronLeft size={16} /> Previous
            </button>
            <span className="body-small" style={{ color: 'var(--color-ash)' }}>
              Page {page + 1} of {data.totalPages}
            </span>
            <button
              className="ghost-pill ghost-pill--dark"
              onClick={() => setPage(page + 1)}
              disabled={page + 1 >= data.totalPages}
              style={{ padding: '8px 20px', fontSize: 14, opacity: page + 1 >= data.totalPages ? 0.4 : 1 }}
            >
              Next <ChevronRight size={16} />
            </button>
          </div>
        </>
      )}
    </div>
  );
}
