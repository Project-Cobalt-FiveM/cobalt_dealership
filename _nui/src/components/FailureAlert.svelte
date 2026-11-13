<script lang="ts">
  import type { Failure } from '../lib/types';
  import Alert from './Alert.svelte';

  interface Props {
    failure: Failure;
  }

  let { failure }: Props = $props();

  const messages: Record<Failure, { title: string; body: string }> = {
    funds: { title: 'Not enough money', body: 'Neither your bank nor your cash covers the price any more.' },
    plate: { title: "That plate isn't allowed", body: 'Use letters and numbers, or leave it empty for a random plate.' },
    account: { title: 'No bank account', body: 'Open one at any bank, then come back to finance.' },
    loans: { title: 'Too many car loans', body: 'Pay off a car you are already financing, then come back.' },
    failed: { title: 'Purchase failed', body: "The car couldn't be registered, so nothing was charged. Try again." },
    unavailable: { title: 'Not for sale', body: "This vehicle or term isn't available here any more." },
  };

  const message = $derived(messages[failure]);
</script>

<Alert title={message.title}>{message.body}</Alert>
