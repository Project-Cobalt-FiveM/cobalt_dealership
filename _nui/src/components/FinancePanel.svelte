<script lang="ts">
  import CaretLeftIcon from 'phosphor-svelte/lib/CaretLeftIcon';
  import type { LoanQuote } from '../lib/finance';
  import { money, percent, weeks } from '../lib/format';
  import { shop } from '../lib/shop.svelte';
  import type { Catalogue, Finance, Vehicle } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import Button from './Button.svelte';
  import ConfirmDialog from './ConfirmDialog.svelte';
  import FailureAlert from './FailureAlert.svelte';

  interface Props {
    catalogue: Catalogue;
    finance: Finance;
    vehicle: Vehicle;
    loan: LoanQuote;
  }

  let { catalogue, finance, vehicle, loan }: Props = $props();

  const rows = $derived([
    ['Price', money(loan.price)],
    [`Interest at ${percent(finance.rate)}`, money(loan.interest)],
    ['Total cost', money(loan.total)],
  ]);
</script>

<header class="flex items-center gap-2.5 border-b border-border px-4 py-3">
  <button
    type="button"
    aria-label="Back"
    onclick={() => (shop.panel = 'configure')}
    class="flex size-7 shrink-0 items-center justify-center rounded-md border border-input bg-secondary text-foreground hover:bg-input {focusRing} {motion}"
  >
    <CaretLeftIcon weight="fill" class="size-3" />
  </button>
  <div class="flex min-w-0 flex-col">
    <h2 class="truncate text-base font-semibold text-foreground">Finance the {vehicle.name}</h2>
    <p class="text-xs text-muted-foreground">{percent(finance.rate)} interest, the same for every buyer</p>
  </div>
</header>

<div class="flex min-h-0 grow flex-col gap-4 overflow-y-auto px-4 py-3 scroll-none animate-fade">
  {#if finance.termsWeeks.length > 1}
    <div class="flex flex-col gap-2">
      <span id="term-label" class="text-13 font-medium text-foreground">Pay it back over</span>
      <div role="radiogroup" aria-labelledby="term-label" class="flex gap-1 rounded-lg border border-border bg-muted p-1">
        {#each finance.termsWeeks as term (term)}
          {@const active = shop.termWeeks === term}
          <button
            type="button"
            role="radio"
            aria-checked={active}
            onclick={() => (shop.termWeeks = term)}
            class="h-8 grow basis-0 rounded-md text-13 font-medium {active ? 'bg-primary text-primary-foreground' : 'text-foreground hover:bg-secondary'} {focusRing} {motion}"
          >
            {weeks(term)}
          </button>
        {/each}
      </div>
    </div>
  {:else}
    <div class="flex items-center justify-between rounded-lg border border-border px-3 py-2.5">
      <span class="text-13 font-medium text-foreground">Term</span>
      <span class="text-sm font-semibold text-foreground">{weeks(loan.termWeeks)}</span>
    </div>
  {/if}

  <dl class="flex flex-col text-13">
    {#each rows as [label, amount] (label)}
      <div class="flex justify-between border-b border-border py-1.5">
        <dt class="text-muted-foreground">{label}</dt>
        <dd class="tabular-nums text-foreground {label === 'Total cost' ? 'font-medium' : ''}">{amount}</dd>
      </div>
    {/each}
    <div class="flex justify-between py-1.5">
      <dt class="text-muted-foreground">Payments</dt>
      <dd class="tabular-nums text-foreground">{loan.termWeeks} × {money(loan.weekly)}</dd>
    </div>
  </dl>

  <p class="text-xs text-muted-foreground">Nothing down. The first payment comes from your bank in 7 days. Miss one and the car is repossessed.</p>
</div>

<footer class="flex flex-col gap-3 border-t border-border p-4">
  {#if shop.confirming}
    <ConfirmDialog kind={shop.confirming} {catalogue} {vehicle} />
  {:else}
    <div class="flex items-end justify-between gap-3">
      <span class="text-13 font-medium text-foreground">Weekly payment</span>
      <span class="text-2xl font-semibold tracking-[-0.02em] whitespace-nowrap tabular-nums text-foreground">{money(loan.weekly)}</span>
    </div>

    {#if shop.failure}
      <FailureAlert failure={shop.failure} />
    {/if}

    <div class="flex gap-2">
      <Button onclick={() => (shop.panel = 'configure')}>Back</Button>
      <Button tone="primary" grow onclick={() => (shop.confirming = 'finance')}>Finance for {money(loan.weekly)} a week</Button>
    </div>
  {/if}
</footer>
