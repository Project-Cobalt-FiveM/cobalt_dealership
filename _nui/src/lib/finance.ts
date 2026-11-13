export interface LoanQuote {
  price: number;
  interest: number;
  total: number;
  weekly: number;
  termWeeks: number;
}

export function quote(price: number, rate: number, termWeeks: number): LoanQuote {
  const interest = Math.round(price * rate);
  const total = price + interest;
  return { price, interest, total, weekly: Math.ceil(total / termWeeks), termWeeks };
}
