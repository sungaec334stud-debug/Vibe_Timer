import React from 'react';

export default function ClassRuleCard() {
  return (
    <div className="class-rule-card">
      <div className="class-rule-tag">The Rule For This Class (Slide 14)</div>
      <div className="class-rule-quote">
        "You may vibe code. You may not submit code you can't explain."
      </div>
      <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '0.4rem', fontStyle: 'italic' }}>
        Low stakes: let vibes flow • High stakes: engineer it properly
      </div>
    </div>
  );
}
