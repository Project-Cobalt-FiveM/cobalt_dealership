import type { NuiCallbacks, NuiMessage } from './types';

declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export type CallbackName = keyof NuiCallbacks;
export type CallbackArgs<K extends CallbackName> = NuiCallbacks[K]['args'];
export type CallbackResult<K extends CallbackName> = NuiCallbacks[K]['result'];

export type MockHandlers = { [K in CallbackName]: (args: CallbackArgs<K>) => CallbackResult<K> };

let mockHandlers: MockHandlers | null = null;

export const inGame = 'GetParentResourceName' in window;

const resourceName = window.GetParentResourceName?.() ?? 'cobalt_dealership';

export function installMock(handlers: MockHandlers): void {
  mockHandlers = handlers;
}

async function mockReply<K extends CallbackName>(handlers: MockHandlers, name: K, args: CallbackArgs<K>): Promise<CallbackResult<K>> {
  await new Promise((resolve) => setTimeout(resolve, 150));
  return handlers[name](args);
}

export async function nui<K extends CallbackName>(name: K, args: CallbackArgs<K>): Promise<CallbackResult<K> | null> {
  if (mockHandlers) return mockReply(mockHandlers, name, args);
  try {
    const response = await fetch(`https://${resourceName}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(args),
    });
    const body: CallbackResult<K> | null = await response.json();
    return body ?? null;
  } catch {
    return null;
  }
}

function isNuiMessage(value: unknown): value is NuiMessage {
  if (typeof value !== 'object' || value === null || !('action' in value)) return false;
  return value.action === 'close' || (value.action === 'open' && 'catalogue' in value && typeof value.catalogue === 'object');
}

export function onNuiMessage(handler: (message: NuiMessage) => void): () => void {
  const listener = (event: MessageEvent<unknown>) => {
    if (isNuiMessage(event.data)) handler(event.data);
  };
  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}
