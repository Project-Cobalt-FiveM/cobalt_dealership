<script lang="ts">
  import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';
  import { money, weeks } from '../lib/format';
  import { shop, type Purchase } from '../lib/shop.svelte';
  import type { Catalogue, Vehicle } from '../lib/types';
  import { focusOnMount } from '../lib/ui';
  import Button from './Button.svelte';

  interface Props {
    kind: Purchase;
    catalogue: Catalogue;
    vehicle: Vehicle;
  }

  let { kind, catalogue, vehicle }: Props = $props();

  const plate = $derived(shop.plate.trim() || 'a random plate');
</script>

<div role="alertdialog" aria-labelledby="confirm-title" aria-describedby="confirm-body" class="flex flex-col gap-3 animate-enter">
  <div class="flex flex-col gap-1">
    {#if kind === 'buy'}
      <h3 id="confirm-title" class="text-sm font-semibold text-foreground">
        Buy the {vehicle.name} for <span class="tabular-nums">{money(shop.price)}</span>?
      </h3>
      <p id="confirm-body" class="text-13 text-muted-foreground">
        Paid from your {shop.payingFrom}, with {plate}. The car and its keys wait outside {catalogue.shop.label}.
      </p>
    {:else if shop.loan}
      <h3 id="confirm-title" class="text-sm font-semibold text-foreground">Finance the {vehicle.name}?</h3>
      <p id="confirm-body" class="text-13 text-muted-foreground">
        <span class="tabular-nums">{money(shop.loan.weekly)}</span> a week for {weeks(shop.loan.termWeeks)}, from your bank,
        <span class="tabular-nums">{money(shop.loan.total)}</span> in all. Miss a payment and the car is taken back.
      </p>
    {/if}
  </div>

  <div class="flex gap-2">
    <Button disabled={shop.busy} onclick={() => (shop.confirming = null)}>Cancel</Button>
    <Button tone="primary" grow attach={focusOnMount} onclick={() => void shop.confirm()}>
      {#if shop.busy}
        <CircleNotchIcon weight="fill" class="size-4 animate-spin" /> {kind === 'buy' ? 'Buying' : 'Asking the dealer'}
      {:else if kind === 'buy'}
        Buy for {money(shop.price)}
      {:else if shop.loan}
        Finance for {money(shop.loan.weekly)} a week
      {/if}
    </Button>
  </div>
</div>
