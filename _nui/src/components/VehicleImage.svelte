<script lang="ts">
  import CarIcon from 'phosphor-svelte/lib/CarIcon';
  import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';

  interface Props {
    src: string;
    alt: string;
    compact?: boolean;
  }

  let { src, alt, compact = false }: Props = $props();

  let state = $state<'loading' | 'ready' | 'missing'>('loading');

  $effect(() => {
    void src;
    state = 'loading';
  });
</script>

<div class="relative aspect-video w-full overflow-hidden bg-muted">
  {#if state !== 'missing'}
    <img
      {src}
      {alt}
      draggable="false"
      loading="lazy"
      decoding="async"
      onload={() => (state = 'ready')}
      onerror={() => (state = 'missing')}
      class="size-full object-contain transition-opacity duration-200 ease-cobalt {state === 'ready' ? 'opacity-100' : 'opacity-0'}"
    />
  {/if}
  {#if state === 'loading'}
    <div class="absolute inset-0 flex items-center justify-center text-muted-foreground">
      {#if compact}
        <CarIcon weight="fill" class="size-5" />
      {:else}
        <CircleNotchIcon weight="fill" class="size-5 animate-spin" />
      {/if}
    </div>
  {:else if state === 'missing'}
    <div class="absolute inset-0 flex flex-col items-center justify-center gap-1.5 text-muted-foreground">
      <CarIcon weight="fill" class={compact ? 'size-5' : 'size-6'} />
      {#if !compact}<span class="text-xs">No preview yet</span>{/if}
    </div>
  {/if}
</div>
