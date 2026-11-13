<script lang="ts">
  import { money } from '../lib/format';
  import type { Vehicle } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import VehicleImage from './VehicleImage.svelte';

  interface Props {
    vehicle: Vehicle;
    selected: boolean;
    onselect: () => void;
  }

  let { vehicle, selected, onselect }: Props = $props();
</script>

<button
  type="button"
  onclick={onselect}
  aria-pressed={selected}
  class="flex shrink-0 items-center gap-3 rounded-md p-1.5 pr-3 text-left {selected ? 'bg-primary' : 'hover:bg-muted'} {focusRing} {motion}"
>
  <div class="w-28 shrink-0 overflow-hidden rounded-sm">
    <VehicleImage src={vehicle.image} alt="{vehicle.brand} {vehicle.name}" compact />
  </div>
  <div class="flex min-w-0 grow basis-0 flex-col">
    <span class="truncate text-13 font-medium text-foreground">{vehicle.name}</span>
    <span class="truncate text-xs {selected ? 'text-primary-foreground' : 'text-muted-foreground'}">{vehicle.brand || '—'}</span>
  </div>
  <span class="text-13 font-medium tabular-nums text-foreground">{money(vehicle.price)}</span>
</button>
