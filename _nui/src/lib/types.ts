export interface Vehicle {
  model: string;
  name: string;
  brand: string;
  price: number;
  category: string;
  type: string;
  image: string;
}

export interface Finance {
  rate: number;
  termsWeeks: number[];
}

export interface Catalogue {
  shop: { id: string; label: string };
  vehicles: Vehicle[];
  categories: string[];
  money: { bank: number; cash: number };
  secondaryColorPrice: number;
  plateMaxLength: number;
  finance: Finance | false;
}

export type NuiMessage = { action: 'open'; catalogue: Catalogue } | { action: 'close' };

export type PlateStatus = 'available' | 'taken' | 'invalid';

export type Failure = 'unavailable' | 'funds' | 'plate' | 'account' | 'loans' | 'failed';

export type PurchaseResult = { ok: true; plate: string } | { ok: false; reason: Failure };

export interface Order {
  model: string;
  primary: string;
  secondary?: string;
  plate: string;
}

export type CameraMove = { kind: 'rotate' | 'zoom' | 'height'; amount: number };

export interface NuiCallbacks {
  select: { args: { model: string }; result: boolean };
  paint: { args: { primary: string; secondary?: string }; result: boolean };
  plate: { args: { text: string }; result: boolean };
  checkPlate: { args: { text: string }; result: PlateStatus };
  camera: { args: CameraMove; result: boolean };
  buy: { args: Order; result: PurchaseResult };
  finance: { args: Order & { termWeeks: number }; result: PurchaseResult };
  close: { args: Record<string, never>; result: boolean };
}
