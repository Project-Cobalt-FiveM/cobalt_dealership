import { quote, type LoanQuote } from './finance';
import { nui } from './nui';
import type { Catalogue, Failure, Order, Vehicle } from './types';

export type SortKey = 'name-asc' | 'name-desc' | 'price-asc' | 'price-desc';

export const sortLabels: Record<SortKey, string> = {
  'name-asc': 'Name, A to Z',
  'name-desc': 'Name, Z to A',
  'price-asc': 'Price, low first',
  'price-desc': 'Price, high first',
};

export type PlateState =
  | { kind: 'empty' }
  | { kind: 'checking' }
  | { kind: 'available' }
  | { kind: 'taken' }
  | { kind: 'rejected'; character: string };

export type Panel = 'configure' | 'finance';

export type Purchase = 'buy' | 'finance';

export const PLATE_ALLOWED = /^[A-Z0-9]$/;

const PLATE_CHECK_DELAY = 300;

const sorters: Record<SortKey, (a: Vehicle, b: Vehicle) => number> = {
  'name-asc': (a, b) => a.name.localeCompare(b.name),
  'name-desc': (a, b) => b.name.localeCompare(a.name),
  'price-asc': (a, b) => a.price - b.price,
  'price-desc': (a, b) => b.price - a.price,
};

function matches(vehicle: Vehicle, query: string): boolean {
  if (query === '') return true;
  const needle = query.toLowerCase();
  return [vehicle.name, vehicle.brand, vehicle.model].some((field) => field.toLowerCase().includes(needle));
}

class Shop {
  catalogue = $state<Catalogue | null>(null);
  category = $state('all');
  search = $state('');
  sort = $state<SortKey>('price-asc');
  selected = $state<Vehicle | null>(null);
  primary = $state('#C20012');
  secondaryOn = $state(false);
  secondary = $state('#0D1116');
  plate = $state('');
  plateState = $state<PlateState>({ kind: 'empty' });
  panel = $state<Panel>('configure');
  termWeeks = $state(4);
  confirming = $state<Purchase | null>(null);
  busy = $state(false);
  failure = $state<Failure | null>(null);

  #plateTimer: ReturnType<typeof setTimeout> | undefined;

  counts = $derived.by(() => {
    const counts = new Map<string, number>();
    for (const vehicle of this.catalogue?.vehicles ?? []) counts.set(vehicle.category, (counts.get(vehicle.category) ?? 0) + 1);
    return counts;
  });

  results = $derived.by(() => {
    const vehicles = this.catalogue?.vehicles ?? [];
    return vehicles
      .filter((vehicle) => (this.category === 'all' || vehicle.category === this.category) && matches(vehicle, this.search.trim()))
      .sort(sorters[this.sort]);
  });

  price = $derived(this.selected ? this.selected.price + (this.secondaryOn ? (this.catalogue?.secondaryColorPrice ?? 0) : 0) : 0);

  affordable = $derived.by(() => {
    const money = this.catalogue?.money;
    return money ? money.bank >= this.price || money.cash >= this.price : false;
  });

  payingFrom = $derived(this.catalogue && this.catalogue.money.bank >= this.price ? 'bank' : 'cash');

  loan = $derived.by((): LoanQuote | null => {
    const finance = this.catalogue?.finance;
    return finance ? quote(this.price, finance.rate, this.termWeeks) : null;
  });

  open(catalogue: Catalogue) {
    this.catalogue = catalogue;
    this.category = catalogue.categories[0] ?? 'all';
    this.search = '';
    this.selected = null;
    this.plate = '';
    this.plateState = { kind: 'empty' };
    this.panel = 'configure';
    this.termWeeks = catalogue.finance ? (catalogue.finance.termsWeeks[0] ?? 4) : 4;
    this.confirming = null;
    this.busy = false;
    this.failure = null;
  }

  close() {
    this.catalogue = null;
    clearTimeout(this.#plateTimer);
  }

  async select(vehicle: Vehicle) {
    this.selected = vehicle;
    this.panel = 'configure';
    this.failure = null;
    await nui('select', { model: vehicle.model });
    this.paint();
    if (this.plate !== '') void nui('plate', { text: this.plate });
  }

  paint() {
    void nui('paint', this.secondaryOn ? { primary: this.primary, secondary: this.secondary } : { primary: this.primary });
  }

  setPlate(text: string) {
    this.plate = text;
    void nui('plate', { text });
    clearTimeout(this.#plateTimer);

    if (text.trim() === '') {
      this.plateState = { kind: 'empty' };
      return;
    }

    this.plateState = { kind: 'checking' };
    this.#plateTimer = setTimeout(() => void this.#checkPlate(text), PLATE_CHECK_DELAY);
  }

  rejectCharacter(character: string) {
    this.plateState = { kind: 'rejected', character };
  }

  async #checkPlate(text: string) {
    const status = await nui('checkPlate', { text });
    if (text !== this.plate) return;
    this.plateState = status === 'available' ? { kind: 'available' } : status === 'taken' ? { kind: 'taken' } : { kind: 'empty' };
  }

  #order(): Order | null {
    if (!this.selected) return null;
    const order: Order = { model: this.selected.model, primary: this.primary, plate: this.plate.trim() };
    if (this.secondaryOn) order.secondary = this.secondary;
    return order;
  }

  async confirm() {
    const kind = this.confirming;
    const order = this.#order();
    if (!kind || !order || this.busy) return;

    this.busy = true;
    const result =
      kind === 'buy' ? await nui('buy', order) : await nui('finance', { ...order, termWeeks: this.termWeeks });
    this.busy = false;
    this.confirming = null;

    if (!result) {
      this.failure = 'failed';
      return;
    }

    if (!result.ok) this.failure = result.reason;
  }
}

export const shop = new Shop();
