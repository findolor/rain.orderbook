<script lang="ts">
  import { orderbookAddress } from '$lib/stores/settings';
  import ModalExecute from '$lib/components/ModalExecute.svelte';
  import { orderRemove, orderRemoveCalldata } from '$lib/services/order';
  import { ethersExecute } from '$lib/services/ethersTx';
  import { toasts } from '$lib/stores/toasts';
  import { reportErrorToSentry } from '$lib/services/sentry';
  import { formatEthersTransactionError } from '$lib/utils/transaction';
  import type { Order as OrderDetailOrder } from '$lib/typeshare/orderDetail';
  import type { Order as OrderListOrder } from '$lib/typeshare/ordersList';

  let openOrderRemoveModal = true;
  export let order: OrderDetailOrder | OrderListOrder;
  let isSubmitting = false;

  async function executeLedger() {
    isSubmitting = true;
    try {
      await orderRemove(order.id);
    } catch (e) {
      reportErrorToSentry(e);
    }
    isSubmitting = false;
  }
  async function executeWalletconnect() {
    isSubmitting = true;
    try {
      const calldata = (await orderRemoveCalldata(order.id)) as Uint8Array;
      const tx = await ethersExecute(calldata, $orderbookAddress!);
      toasts.success('Transaction sent successfully!');
      await tx.wait(1);
    } catch (e) {
      reportErrorToSentry(e);
      toasts.error(formatEthersTransactionError(e));
    }
    isSubmitting = false;
  }
</script>

<ModalExecute
  bind:open={openOrderRemoveModal}
  title="Remove Order"
  execButtonLabel="Remove Order"
  {executeLedger}
  {executeWalletconnect}
  bind:isSubmitting
/>
