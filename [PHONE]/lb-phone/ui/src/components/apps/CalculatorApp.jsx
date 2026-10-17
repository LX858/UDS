import React, { useState } from 'react';

export default function CalculatorApp() {
  const [display, setDisplay] = useState('0');
  const [previousValue, setPreviousValue] = useState(null);
  const [operation, setOperation] = useState(null);

  const handleNumberClick = (num) => {
    setDisplay(display === '0' ? String(num) : display + num);
  };

  const handleOperation = (op) => {
    setPreviousValue(parseFloat(display));
    setOperation(op);
    setDisplay('0');
  };

  const handleEquals = () => {
    if (!operation || previousValue === null) return;
    const result = eval(`${previousValue} ${operation} ${display}`);
    setDisplay(String(result));
    setPreviousValue(null);
    setOperation(null);
  };

  const handleClear = () => {
    setDisplay('0');
    setPreviousValue(null);
    setOperation(null);
  };

  return (
    <div className="calculator-app">
      <div className="calc-display">{display}</div>
      <div className="calc-grid">
        <button onClick={handleClear} className="calc-btn clear">
          C
        </button>
        <button onClick={() => handleOperation('/')} className="calc-btn operator">
          ÷
        </button>
        <button onClick={() => handleOperation('*')} className="calc-btn operator">
          ×
        </button>
        <button onClick={() => handleOperation('-')} className="calc-btn operator">
          −
        </button>

        {[7, 8, 9].map((num) => (
          <button key={num} onClick={() => handleNumberClick(num)} className="calc-btn">
            {num}
          </button>
        ))}
        <button onClick={() => handleOperation('+')} className="calc-btn operator">
          +
        </button>

        {[4, 5, 6].map((num) => (
          <button key={num} onClick={() => handleNumberClick(num)} className="calc-btn">
            {num}
          </button>
        ))}

        {[1, 2, 3].map((num) => (
          <button key={num} onClick={() => handleNumberClick(num)} className="calc-btn">
            {num}
          </button>
        ))}

        <button onClick={() => handleNumberClick(0)} className="calc-btn zero">
          0
        </button>
        <button onClick={() => setDisplay(display + '.')} className="calc-btn">
          .
        </button>
        <button onClick={handleEquals} className="calc-btn equals">
          =
        </button>
      </div>
    </div>
  );
}
