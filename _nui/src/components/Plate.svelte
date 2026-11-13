<script lang="ts">
  import CheckCircleIcon from 'phosphor-svelte/lib/CheckCircleIcon';
  import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';
  import WarningIcon from 'phosphor-svelte/lib/WarningIcon';
  import XCircleIcon from 'phosphor-svelte/lib/XCircleIcon';
  import { PLATE_ALLOWED, type PlateState } from '../lib/shop.svelte';
  import { motion } from '../lib/ui';
  import Kbd from './Kbd.svelte';

  interface Props {
    value: string;
    maxLength: number;
    plateState: PlateState;
    onchange: (text: string) => void;
    onreject: (character: string) => void;
  }

  let { value, maxLength, plateState, onchange, onreject }: Props = $props();

  let editing = $state(false);
  let before = '';
  let input = $state<HTMLInputElement>();

  const ring = $derived(
    plateState.kind === 'taken' ? 'border-destructive' : editing ? 'border-primary' : 'border-transparent',
  );

  function handleInput(event: Event & { currentTarget: HTMLInputElement }) {
    const typed = event.currentTarget.value.toUpperCase();
    const rejected = [...typed].find((character) => !PLATE_ALLOWED.test(character));
    const clean = [...typed].filter((character) => PLATE_ALLOWED.test(character)).join('').slice(0, maxLength);

    event.currentTarget.value = clean;
    if (clean !== value) onchange(clean);
    if (rejected) onreject(rejected);
  }

  function handleKey(event: KeyboardEvent) {
    if (event.key === 'Enter') {
      input?.blur();
    } else if (event.key === 'Escape') {
      event.stopPropagation();
      if (before !== value) onchange(before);
      input?.blur();
    }
  }
</script>

<div class="flex flex-col gap-2">
  <div class="flex items-center justify-between">
    <label for="plate" class="text-13 font-medium text-foreground">Number plate</label>
    <span class="text-xs text-muted-foreground">Click to edit</span>
  </div>

  <div class="flex items-center gap-3">
    <div class="flex shrink-0 rounded-lg border-2 p-0.5 {ring} {motion}">
      <div
        class="relative flex h-20 w-40 flex-col items-center rounded-md border-2 bg-plate pt-1 {value === '' && !editing
          ? 'border-dashed border-muted-foreground'
          : 'border-plate-ink'}"
      >
        {#each ['top-1.5 left-2.5', 'top-1.5 right-2.5', 'bottom-1.5 left-2.5', 'bottom-1.5 right-2.5'] as spot (spot)}
          <span class="absolute size-1.5 rounded-full border border-muted-foreground bg-plate-bolt {spot}"></span>
        {/each}
        <span class="font-plate-script text-sm leading-4 text-plate-script">San Andreas</span>
        <input
          id="plate"
          bind:this={input}
          {value}
          maxlength={maxLength}
          placeholder={editing ? '' : 'RANDOM'}
          spellcheck="false"
          autocomplete="off"
          aria-describedby="plate-status"
          oninput={handleInput}
          onkeydown={handleKey}
          onfocus={() => {
            before = value;
            editing = true;
          }}
          onblur={() => (editing = false)}
          class="w-full bg-plate text-center font-plate text-[2rem] leading-11 font-semibold tracking-[0.04em] text-plate-ink caret-cobalt outline-none placeholder:text-muted-foreground"
        />
      </div>
    </div>

    <div id="plate-status" aria-live="polite" class="flex flex-col gap-1.5">
      {#if plateState.kind === 'checking'}
        <span class="flex items-center gap-1.5 text-13 font-medium text-foreground">
          <CircleNotchIcon weight="fill" class="size-4 animate-spin text-muted-foreground" /> Checking
        </span>
      {:else if plateState.kind === 'available'}
        <span class="flex items-center gap-1.5 text-13 font-medium text-foreground">
          <CheckCircleIcon weight="fill" class="size-4 text-success" /> Available
        </span>
      {:else if plateState.kind === 'taken'}
        <span class="flex items-center gap-1.5 text-13 font-medium text-foreground">
          <XCircleIcon weight="fill" class="size-4 text-destructive" /> Taken
        </span>
      {:else if plateState.kind === 'rejected'}
        <span class="flex items-center gap-1.5 text-13 font-medium text-foreground">
          <WarningIcon weight="fill" class="size-4 text-warning" />
          {plateState.character === ' ' ? "Spaces aren't allowed" : `"${plateState.character}" isn't allowed`}
        </span>
      {/if}
      <span class="w-32 text-xs text-muted-foreground">
        {#if plateState.kind === 'taken'}
          Someone owns this plate. Try another.
        {:else if plateState.kind === 'rejected'}
          Use letters and numbers.
        {:else if value === ''}
          Leave it empty and you get a random plate.
        {:else}
          <span class="tabular-nums">{value.length} / {maxLength}</span>. Letters and numbers.
        {/if}
      </span>
    </div>
  </div>

  {#if editing}
    <div class="flex items-center gap-3 animate-fade">
      <Kbd keys={['Enter']} label="Keep plate" />
      <Kbd keys={['Esc']} label="Undo changes" />
    </div>
  {/if}
</div>
