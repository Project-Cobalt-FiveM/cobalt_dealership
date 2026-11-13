<script lang="ts">
  import type { Snippet } from 'svelte';
  import WarningIcon from 'phosphor-svelte/lib/WarningIcon';

  interface Props {
    title: string;
    tone?: 'destructive' | 'warning';
    children: Snippet;
  }

  let { title, tone = 'destructive', children }: Props = $props();
</script>

<div role="alert" class="flex gap-2.5 rounded-md border border-border bg-muted p-3 animate-fade">
  <WarningIcon weight="fill" class="mt-0.5 size-4 shrink-0 {tone === 'destructive' ? 'text-destructive' : 'text-warning'}" />
  <div class="flex flex-col gap-0.5">
    <p class="text-sm font-medium text-foreground">{title}</p>
    <p class="text-13 leading-[1.125rem] text-muted-foreground">{@render children()}</p>
  </div>
</div>
