<script lang="ts">
  import CreditCardIcon from 'phosphor-svelte/lib/CreditCardIcon';
  import { categoryLabel, money } from '../lib/format';
  import { shop } from '../lib/shop.svelte';
  import type { Catalogue, Vehicle } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import Alert from './Alert.svelte';
  import Button from './Button.svelte';
  import ConfirmDialog from './ConfirmDialog.svelte';
  import FailureAlert from './FailureAlert.svelte';
  import Plate from './Plate.svelte';
  import Swatches from './Swatches.svelte';

  interface Props {
    catalogue: Catalogue;
    vehicle: Vehicle;
  }

  let { catalogue, vehicle }: Props = $props();

  const PRIMARY = [
    '#0D1116', '#1C1D21', '#32383D', '#585853', '#848988', '#C8C8C8', '#F5F5F5', '#FFFFFF',
    '#C20012', '#7B1A22', '#1F4CA8', '#214559', '#00613A', '#F2AD30', '#CF6A23', '#6B1F7B',
  ] as const;

  const SECONDARY = ['#0D1116', '#1C1D21', '#32383D', '#848988', '#F5F5F5', '#C20012', '#1F4CA8', '#F2AD30'] as const;

  function pickPrimary(colour: string) {
    shop.primary = colour;
    shop.paint();
  }

  function pickSecondary(colour: string) {
    shop.secondary = colour;
    shop.paint();
  }

  function toggleSecondary() {
    shop.secondaryOn = !shop.secondaryOn;
    shop.paint();
  }
</script>

<header class="flex items-end justify-between gap-3 border-b border-border px-4 py-3">
  <div class="flex min-w-0 flex-col">
    <p class="truncate text-xs text-muted-foreground">{vehicle.brand ? `${vehicle.brand}, ` : ''}{categoryLabel(vehicle.category).toLowerCase()}</p>
    <h2 class="truncate text-xl font-semibold tracking-[-0.01em] text-foreground">{vehicle.name}</h2>
  </div>
  <span class="text-sm font-medium tabular-nums text-muted-foreground">{money(vehicle.price)}</span>
</header>

<div class="flex min-h-0 grow flex-col gap-4 overflow-y-auto px-4 py-3 scroll-none">
  <div class="flex flex-col gap-2">
    <span class="text-13 font-medium text-foreground">Primary colour</span>
    <Swatches colours={PRIMARY} value={shop.primary} label="Primary colour" onpick={pickPrimary} />
  </div>

  <div class="flex flex-col gap-2">
    <div class="flex items-center gap-3">
      <div class="flex grow basis-0 flex-col">
        <span id="secondary-label" class="text-13 font-medium text-foreground">Secondary colour</span>
        <span class="text-xs text-muted-foreground">Adds <span class="tabular-nums">{money(catalogue.secondaryColorPrice)}</span></span>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={shop.secondaryOn}
        aria-labelledby="secondary-label"
        onclick={toggleSecondary}
        class="flex h-5 w-9 shrink-0 rounded-full p-0.5 {shop.secondaryOn ? 'justify-end bg-primary' : 'justify-start bg-secondary'} {focusRing} {motion}"
      >
        <span class="size-4 rounded-full bg-foreground"></span>
      </button>
    </div>
    {#if shop.secondaryOn}
      <div class="animate-fade">
        <Swatches colours={SECONDARY} value={shop.secondary} label="Secondary colour" onpick={pickSecondary} />
      </div>
    {/if}
  </div>

  <Plate
    value={shop.plate}
    maxLength={catalogue.plateMaxLength}
    plateState={shop.plateState}
    onchange={(text) => shop.setPlate(text)}
    onreject={(character) => shop.rejectCharacter(character)}
  />
</div>

<footer class="flex flex-col gap-3 border-t border-border p-4">
  {#if shop.confirming}
    <ConfirmDialog kind={shop.confirming} {catalogue} {vehicle} />
  {:else}
    <div class="flex items-end justify-between gap-3">
      <div class="flex flex-col">
        <span class="text-13 font-medium text-foreground">Total</span>
        <span class="text-xs text-muted-foreground">Bank first, then cash</span>
      </div>
      <span class="text-2xl font-semibold tracking-[-0.02em] whitespace-nowrap tabular-nums text-foreground">{money(shop.price)}</span>
    </div>

    {#if !shop.affordable}
      <Alert title="Not enough money">
        You have <span class="tabular-nums">{money(catalogue.money.bank)}</span> in the bank and
        <span class="tabular-nums">{money(catalogue.money.cash)}</span> cash{catalogue.finance ? '. You can finance it instead' : ''}.
      </Alert>
    {:else if shop.failure && shop.panel === 'configure'}
      <FailureAlert failure={shop.failure} />
    {/if}

    <div class="flex gap-2">
      {#if shop.affordable}
        {#if catalogue.finance}
          <Button onclick={() => (shop.panel = 'finance')}>
            <CreditCardIcon weight="fill" class="size-4" /> Finance
          </Button>
        {/if}
        <Button tone="primary" grow onclick={() => (shop.confirming = 'buy')}>Buy for {money(shop.price)}</Button>
      {:else}
        <Button grow disabled>Buy for {money(shop.price)}</Button>
        {#if catalogue.finance}
          <Button tone="primary" onclick={() => (shop.panel = 'finance')}>
            <CreditCardIcon weight="fill" class="size-4" /> Finance instead
          </Button>
        {/if}
      {/if}
    </div>
  {/if}
</footer>
