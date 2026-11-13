<script lang="ts" module>
  export type ButtonTone = 'primary' | 'secondary';
  export type ButtonSize = 'md' | 'lg';
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import { focusRing, motion } from '../lib/ui';

  interface Props {
    tone?: ButtonTone;
    size?: ButtonSize;
    type?: 'button' | 'submit';
    disabled?: boolean;
    grow?: boolean;
    attach?: Attachment<HTMLElement>;
    onclick?: () => void;
    children: Snippet;
  }

  let { tone = 'secondary', size = 'md', type = 'button', disabled = false, grow = false, attach, onclick, children }: Props = $props();

  const tones: Record<ButtonTone, string> = {
    primary: 'border-cobalt bg-primary font-semibold text-primary-foreground hover:border-cobalt-hover hover:bg-cobalt-hover',
    secondary: 'border-input bg-secondary font-medium text-foreground hover:bg-input',
  };

  const sizes: Record<ButtonSize, string> = {
    md: 'h-9 px-4',
    lg: 'h-10 px-6',
  };

  const look = $derived(disabled ? 'border-input bg-secondary font-medium text-muted-foreground cursor-not-allowed' : tones[tone]);
</script>

<button
  {type}
  {disabled}
  {onclick}
  {@attach attach}
  class="flex items-center justify-center gap-2 rounded-md border text-sm tabular-nums {sizes[size]} {look} {grow ? 'grow basis-0' : ''} {focusRing} {motion}"
>
  {@render children()}
</button>
