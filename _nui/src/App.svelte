<script lang="ts">
  import CarIcon from 'phosphor-svelte/lib/CarIcon';
  import Catalogue from './components/Catalogue.svelte';
  import Configure from './components/Configure.svelte';
  import FinancePanel from './components/FinancePanel.svelte';
  import Kbd from './components/Kbd.svelte';
  import { nui, onNuiMessage } from './lib/nui';
  import { shop } from './lib/shop.svelte';
  import type { CameraMove } from './lib/types';

  const ROTATE_SPEED = 0.4;
  const HEIGHT_STEP = 0.15;

  let dragging = false;

  $effect(() =>
    onNuiMessage((message) => {
      if (message.action === 'open') shop.open(message.catalogue);
      else shop.close();
    }),
  );

  function camera(move: CameraMove) {
    if (shop.selected) void nui('camera', move);
  }

  function typing(target: EventTarget | null): boolean {
    return target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement;
  }

  function handleKey(event: KeyboardEvent) {
    if (!shop.catalogue) return;

    if (event.key === 'Escape') {
      if (shop.confirming) {
        if (!shop.busy) shop.confirming = null;
      } else if (shop.panel === 'finance') {
        shop.panel = 'configure';
      } else {
        void nui('close', {});
      }
      return;
    }

    if (typing(event.target) || shop.confirming) return;

    const key = event.key.toLowerCase();
    if (key === 'w') camera({ kind: 'height', amount: HEIGHT_STEP });
    else if (key === 's') camera({ kind: 'height', amount: -HEIGHT_STEP });
  }
</script>

<svelte:window
  onkeydown={handleKey}
  onmouseup={() => (dragging = false)}
  onmousemove={(event) => dragging && camera({ kind: 'rotate', amount: event.movementX * ROTATE_SPEED })}
/>

{#if shop.catalogue}
  {@const catalogue = shop.catalogue}
  <main class="relative h-screen w-screen overflow-hidden text-foreground">
    <div
      role="presentation"
      class="absolute inset-y-0 right-[23.25rem] left-[27rem] flex items-center justify-center {shop.selected && !shop.confirming
        ? 'cursor-grab active:cursor-grabbing'
        : ''}"
      onmousedown={() => (dragging = !shop.confirming)}
      onwheel={(event) => camera({ kind: 'zoom', amount: event.deltaY < 0 ? 1 : -1 })}
    >
      {#if shop.selected}
        <div class="absolute bottom-6 flex h-9 items-center gap-4 rounded-lg border border-border bg-card px-3 animate-fade">
          <Kbd keys={['Drag']} label="Rotate" />
          <Kbd keys={['Scroll']} label="Zoom" />
          <Kbd keys={['W', 'S']} label="Camera height" />
        </div>
      {/if}
    </div>

    <Catalogue {catalogue} />

    <aside
      aria-label="Your vehicle"
      class="absolute top-6 right-6 flex max-h-[calc(100%-3rem)] w-[21.25rem] flex-col overflow-hidden rounded-lg border border-border bg-card animate-enter"
    >
      {#if !shop.selected}
        <div class="flex items-center gap-3 p-4">
          <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-secondary">
            <CarIcon weight="fill" class="size-4 text-muted-foreground" />
          </div>
          <div class="flex flex-col">
            <p class="text-sm font-semibold text-foreground">Pick a vehicle</p>
            <p class="text-13 text-muted-foreground">It rolls into the showroom, ready to paint and buy.</p>
          </div>
        </div>
      {:else if shop.panel === 'finance' && catalogue.finance && shop.loan}
        <FinancePanel {catalogue} finance={catalogue.finance} vehicle={shop.selected} loan={shop.loan} />
      {:else}
        <Configure {catalogue} vehicle={shop.selected} />
      {/if}
    </aside>
  </main>
{/if}
