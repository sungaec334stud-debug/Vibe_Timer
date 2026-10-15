import React from 'react';

export default function SessionStats({ stats }) {
  const totalMins = stats?.totalMinutes || 0;
  const hrs = Math.floor(totalMins / 60);
  const remainingMins = totalMins % 60;
  const timeFormatted = hrs > 0 ? `${hrs}h ${remainingMins}m` : `${totalMins}m`;

  return (
    <div className="mobile-stats-row">
      <div>
        <div className="stat-metric-label">Total Focus</div>
        <div className="stat-metric-val">{timeFormatted}</div>
      </div>
      <div>
        <div className="stat-metric-label">Sessions</div>
        <div className="stat-metric-val" style={{ color: 'var(--accent-purple-light)' }}>
          {stats?.totalSessions || 0}
        </div>
      </div>
      <div>
        <div className="stat-metric-label">Prompts Logged</div>
        <div className="stat-metric-val" style={{ color: 'var(--accent-cyan)' }}>
          {stats?.totalPrompts || 0}
        </div>
      </div>
    </div>
  );
}
