<script lang="ts">
  import CaretDownIcon from 'phosphor-svelte/lib/CaretDownIcon';
  import CheckIcon from 'phosphor-svelte/lib/CheckIcon';
  import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';
  import SortAscendingIcon from 'phosphor-svelte/lib/SortAscendingIcon';
  import { categoryLabel, categoryNoun, money } from '../lib/format';
  import { shop, sortLabels, type SortKey } from '../lib/shop.svelte';
  import type { Catalogue } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import BrandMark from './BrandMark.svelte';
  import Kbd from './Kbd.svelte';
  import VehicleRow from './VehicleRow.svelte';

  interface Props {
    catalogue: Catalogue;
  }

  let { catalogue }: Props = $props();

  let menu = $state<'category' | 'sort' | null>(null);

  const sortKeys = Object.keys(sortLabels).filter((key): key is SortKey => key in sortLabels);
  const categories = $derived(['all', ...catalogue.categories]);

  const countOf = (category: string): number =>
    category === 'all' ? catalogue.vehicles.length : (shop.counts.get(category) ?? 0);

  const labelOf = (category: string): string => (category === 'all' ? 'All vehicles' : categoryLabel(category));

  function toggle(which: 'category' | 'sort') {
    menu = menu === which ? null : which;
  }

  function pickCategory(category: string) {
    shop.category = category;
    menu = null;
  }

  function pickSort(key: SortKey) {
    shop.sort = key;
    menu = null;
  }
</script>

<section
  aria-label={catalogue.shop.label}
  class="absolute top-6 left-6 flex h-[calc(100%-3rem)] w-[25.5rem] flex-col overflow-hidden rounded-lg border border-border bg-card animate-enter"
>
  <header class="flex items-center gap-2.5 border-b border-border px-4 py-3">
    <BrandMark class="size-6 shrink-0" />
    <div class="flex min-w-0 grow basis-0 flex-col">
      <h1 class="truncate text-sm font-semibold text-foreground">{catalogue.shop.label}</h1>
      <p class="text-xs text-muted-foreground tabular-nums">{catalogue.vehicles.length} vehicles</p>
    </div>
    <Kbd keys={['Esc']} label="Leave" />
  </header>

  <div class="relative flex flex-col gap-2 border-b border-border p-3">
    <div class="flex gap-2">
      <button
        type="button"
        onclick={() => toggle('category')}
        aria-expanded={menu === 'category'}
        aria-haspopup="listbox"
        class="flex h-8 min-w-0 grow basis-0 items-center justify-between gap-2 rounded-md border border-input bg-secondary px-2.5 text-13 font-medium text-foreground hover:bg-input {focusRing} {motion}"
      >
        <span class="truncate">{labelOf(shop.category)}</span>
        <span class="flex items-center gap-1.5 text-muted-foreground">
          <span class="text-xs tabular-nums">{countOf(shop.category)}</span>
          <CaretDownIcon weight="fill" class="size-3" />
        </span>
      </button>
      <button
        type="button"
        onclick={() => toggle('sort')}
        aria-expanded={menu === 'sort'}
        aria-label="Sort: {sortLabels[shop.sort]}"
        title={sortLabels[shop.sort]}
        class="flex size-8 shrink-0 items-center justify-center rounded-md border border-input bg-secondary text-muted-foreground hover:bg-input hover:text-foreground {focusRing} {motion}"
      >
        <SortAscendingIcon weight="fill" class="size-4" />
      </button>
    </div>

    <label class="flex h-8 items-center gap-2 rounded-md border border-input px-2.5 focus-within:ring-2 focus-within:ring-cobalt {motion}">
      <MagnifyingGlassIcon weight="fill" class="size-3.5 shrink-0 text-muted-foreground" />
      <input
        bind:value={shop.search}
        placeholder="Search {categoryNoun(shop.category)}"
        aria-label="Search vehicles"
        class="w-full bg-transparent text-13 text-foreground outline-none placeholder:text-muted-foreground"
      />
    </label>

    {#if menu === 'category'}
      <div role="listbox" aria-label="Categories" class="absolute top-[2.75rem] right-3 left-3 z-10 flex max-h-[24rem] flex-col overflow-y-auto rounded-lg border border-border bg-popover p-1 shadow-lg scroll-none animate-pop">
        {#each categories as category (category)}
          {@const active = shop.category === category}
          <button
            type="button"
            role="option"
            aria-selected={active}
            onclick={() => pickCategory(category)}
            class="flex h-8 shrink-0 items-center justify-between rounded-md px-2 text-13 {active
              ? 'bg-primary font-medium text-primary-foreground'
              : 'text-foreground hover:bg-muted'} {focusRing}"
          >
            <span>{labelOf(category)}</span>
            <span class="text-xs tabular-nums {active ? '' : 'text-muted-foreground'}">{countOf(category)}</span>
          </button>
        {/each}
      </div>
    {:else if menu === 'sort'}
      <div role="menu" class="absolute top-[2.75rem] right-3 z-10 flex w-48 flex-col rounded-lg border border-border bg-popover p-1 shadow-lg animate-pop">
        {#each sortKeys as key (key)}
          <button
            type="button"
            role="menuitemradio"
            aria-checked={shop.sort === key}
            onclick={() => pickSort(key)}
            class="flex h-8 items-center justify-between rounded-md px-2 text-left text-13 text-foreground hover:bg-muted {shop.sort === key
              ? 'bg-muted'
              : ''} {focusRing}"
          >
            {sortLabels[key]}
            {#if shop.sort === key}<CheckIcon weight="fill" class="size-3.5 text-cobalt" />{/if}
          </button>
        {/each}
      </div>
    {/if}
  </div>

  {#if shop.results.length > 0}
    <div class="flex min-h-0 grow flex-col gap-1 overflow-y-auto p-2 scroll-none">
      {#each shop.results as vehicle (vehicle.model)}
        <VehicleRow {vehicle} selected={shop.selected?.model === vehicle.model} onselect={() => void shop.select(vehicle)} />
      {/each}
    </div>
  {:else}
    <div class="flex grow flex-col items-center justify-center gap-2.5 p-6 text-center animate-fade">
      <div class="flex size-9 items-center justify-center rounded-lg bg-secondary">
        <MagnifyingGlassIcon weight="fill" class="size-4 text-muted-foreground" />
      </div>
      <p class="text-sm font-semibold text-foreground">
        {shop.search.trim() === '' ? 'Nothing here yet' : `No ${categoryNoun(shop.category)} match "${shop.search.trim()}"`}
      </p>
      <p class="text-13 text-muted-foreground">Search looks at name, brand and model.</p>
      <div class="flex gap-2">
        <button
          type="button"
          onclick={() => (shop.search = '')}
          class="h-8 rounded-md border border-input bg-secondary px-3 text-13 font-medium text-foreground hover:bg-input {focusRing} {motion}"
        >
          Clear search
        </button>
        <button
          type="button"
          onclick={() => (shop.category = 'all')}
          class="h-8 rounded-md border border-input bg-secondary px-3 text-13 font-medium text-foreground hover:bg-input {focusRing} {motion}"
        >
          All vehicles
        </button>
      </div>
    </div>
  {/if}

  <footer class="flex items-center justify-between gap-2 border-t border-border px-4 py-2.5 text-xs">
    <span class="text-muted-foreground">You have</span>
    <span class="font-medium tabular-nums text-foreground">{money(catalogue.money.bank)} bank · {money(catalogue.money.cash)} cash</span>
  </footer>
</section>
