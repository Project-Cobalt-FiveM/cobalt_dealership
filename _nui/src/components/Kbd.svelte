<script lang="ts">
  interface Props {
    keys: string[];
    label: string;
  }

  let { keys, label }: Props = $props();
</script>

<div class="flex items-center gap-1.5">
  {#each keys as key (key)}
    <span class="rounded-sm border border-border bg-muted px-1.5 text-xs leading-4 text-foreground">{key}</span>
  {/each}
  <span class="text-xs text-muted-foreground">{label}</span>
</div>
