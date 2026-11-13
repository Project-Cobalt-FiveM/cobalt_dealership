const dollars = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export const money = (amount: number): string => dollars.format(amount);

export const percent = (rate: number): string => `${Math.round(rate * 1000) / 10}%`;

export const weeks = (count: number): string => (count === 1 ? '1 week' : `${count} weeks`);

const categoryLabels: Record<string, string> = {
  compacts: 'Compacts',
  sedans: 'Sedans',
  suvs: 'SUVs',
  coupes: 'Coupes',
  sports: 'Sports',
  sportsclassic: 'Sports classics',
  super: 'Super',
  muscle: 'Muscle',
  offroad: 'Off-road',
  vans: 'Vans',
  motorcycles: 'Motorcycles',
  openwheel: 'Open wheel',
  cycles: 'Cycles',
  boats: 'Boats',
  helicopters: 'Helicopters',
  planes: 'Planes',
  commercial: 'Commercial',
  industrial: 'Industrial',
  utility: 'Utility',
};

export const categoryLabel = (category: string): string =>
  categoryLabels[category] ?? category.charAt(0).toUpperCase() + category.slice(1);

export const categoryNoun = (category: string): string => (category === 'all' ? 'vehicles' : categoryLabel(category).toLowerCase());
