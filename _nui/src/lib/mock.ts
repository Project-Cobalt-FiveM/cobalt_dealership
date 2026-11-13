import { installMock, type MockHandlers } from './nui';
import { shop, type Panel, type Purchase } from './shop.svelte';
import type { Catalogue, NuiMessage, Vehicle } from './types';

const params = new URLSearchParams(window.location.search);

function silhouette(paint: string): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90"><rect width="160" height="90" fill="#1C1C1C"/><rect y="62" width="160" height="28" fill="#171717"/><path d="M12 60C12 54 16 51 24 50L48 47C58 38 70 34 88 34C104 34 116 38 128 46L144 49C150 50 152 54 152 59V62C152 64 150 65 148 65H14C13 65 12 64 12 62Z" fill="${paint}"/><path d="M60 46C68 39 78 37 88 37C98 37 106 40 114 46Z" fill="#0A0A0A"/><path d="M31 64a9 9 0 1 0 18 0a9 9 0 1 0-18 0ZM115 64a9 9 0 1 0 18 0a9 9 0 1 0-18 0Z" fill="#0A0A0A"/></svg>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

const stock: [string, string, string, number, string, string][] = [
  ['kuruma', 'Kuruma', 'Karin', 72000, 'sports', '#848988'],
  ['elegy', 'Elegy RH8', 'Annis', 89000, 'sports', '#F2AD30'],
  ['carbonizzare', 'Carbonizzare', 'Grotti', 95000, 'sports', '#7B1A22'],
  ['feltzer2', 'Feltzer', 'Benefactor', 97000, 'sports', ''],
  ['comet2', 'Comet', 'Pfister', 100000, 'sports', '#C20012'],
  ['banshee', 'Banshee', 'Bravado', 105000, 'sports', '#585853'],
  ['massacro', 'Massacro', 'Dewbauchee', 110000, 'sports', '#00613A'],
  ['ninef', '9F', 'Obey', 120000, 'sports', '#CF6A23'],
  ['jester', 'Jester', 'Dinka', 135000, 'sports', '#1F4CA8'],
  ['blista', 'Blista', 'Dinka', 16000, 'compacts', '#F5F5F5'],
  ['issi2', 'Issi', 'Weeny', 18000, 'compacts', '#CF6A23'],
  ['tailgater', 'Tailgater', 'Obey', 38000, 'sedans', '#32383D'],
  ['schafter2', 'Schafter', 'Benefactor', 52000, 'sedans', '#0D1116'],
  ['baller2', 'Baller', 'Gallivanter', 64000, 'suvs', '#C8C8C8'],
  ['zentorno', 'Zentorno', 'Pegassi', 725000, 'super', '#F2AD30'],
  ['dominator', 'Dominator', 'Vapid', 62000, 'muscle', '#C20012'],
  ['bati', 'Bati 801', 'Pegassi', 15000, 'motorcycles', '#1C1D21'],
];

const vehicles: Vehicle[] = stock.map(([model, name, brand, price, category, paint]) => ({
  model,
  name,
  brand,
  price,
  category,
  type: category === 'motorcycles' ? 'bike' : 'automobile',
  image: params.get('silhouettes') === '1' ? silhouette(paint || '#585853') : `https://docs.fivem.net/vehicles/${paint === '' ? 'nopreview' : model}.webp`,
}));

const poor = params.get('poor') === '1';
const terms = (params.get('terms') ?? '4').split(',').map(Number).filter((term) => term > 0);

const catalogue: Catalogue = {
  shop: { id: 'pdm', label: 'Premium Deluxe Motorsport' },
  vehicles,
  categories: ['compacts', 'sedans', 'suvs', 'sports', 'super', 'muscle', 'motorcycles'],
  money: poor ? { bank: 64200, cash: 4850 } : { bank: 142300, cash: 4850 },
  secondaryColorPrice: 2000,
  plateMaxLength: 8,
  finance: { rate: 0.05, termsWeeks: terms.length > 0 ? terms : [4] },
};

const handlers: MockHandlers = {
  select: () => true,
  paint: () => true,
  plate: () => true,
  checkPlate: ({ text }) => (text === 'SULTAN' ? 'taken' : 'available'),
  camera: () => true,
  buy: ({ plate }) => ({ ok: true, plate: plate === '' ? '4KXR92TB' : plate }),
  finance: ({ plate }) => ({ ok: true, plate: plate === '' ? '4KXR92TB' : plate }),
  close: () => true,
};

installMock(handlers);
document.body.style.background = '#3F3F46';

const open: NuiMessage = { action: 'open', catalogue };
window.postMessage(open, '*');

const isPanel = (value: string | null): value is Panel => value === 'configure' || value === 'finance';
const isPurchase = (value: string | null): value is Purchase => value === 'buy' || value === 'finance';

setTimeout(() => {
  const requested = params.get('select');
  const vehicle = vehicles.find((entry) => entry.model === requested);

  if (params.get('search') !== null) shop.search = params.get('search') ?? '';
  if (!vehicle) return;

  shop.category = vehicle.category;
  void shop.select(vehicle);
  shop.secondaryOn = params.get('secondary') === '1';
  if (params.get('plate') !== null) shop.setPlate(params.get('plate') ?? '');

  const panel = params.get('panel');
  if (isPanel(panel)) shop.panel = panel;

  const confirming = params.get('confirm');
  if (isPurchase(confirming)) shop.confirming = confirming;

  const termWeeks = Number(params.get('term'));
  if (termWeeks > 0) shop.termWeeks = termWeeks;
}, 50);
