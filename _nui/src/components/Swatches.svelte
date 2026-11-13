<script lang="ts">
  import { focusRing, motion } from '../lib/ui';

  interface Props {
    colours: readonly string[];
    value: string;
    label: string;
    onpick: (colour: string) => void;
  }

  let { colours, value, label, onpick }: Props = $props();
</script>

<div role="radiogroup" aria-label={label} class="grid grid-cols-8 gap-1">
  {#each colours as colour (colour)}
    {@const selected = colour.toUpperCase() === value.toUpperCase()}
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      aria-label={colour}
      onclick={() => onpick(colour)}
      class="flex h-7 rounded-md {selected ? 'border-2 border-primary p-0.5' : 'border border-input'} {focusRing} {motion}"
    >
      <span class="grow {selected ? 'rounded-[0.1875rem]' : 'rounded-[0.3125rem]'}" style:background-color={colour}></span>
    </button>
  {/each}
</div>
