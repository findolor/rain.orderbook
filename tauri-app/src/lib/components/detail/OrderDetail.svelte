<script lang="ts">
  import CardProperty from './../../../lib/components/CardProperty.svelte';
  import { Button, TabItem, Tabs } from 'flowbite-svelte';
  import { walletAddressMatchesOrBlank } from '$lib/stores/wallets';
  import BadgeActive from '$lib/components/BadgeActive.svelte';
  import { formatTimestampSecondsAsLocal } from '$lib/utils/time';
  import ButtonVaultLink from '$lib/components/ButtonVaultLink.svelte';
  import Hash from '$lib/components/Hash.svelte';
  import { HashType } from '$lib/types/hash';
  import CodeMirrorRainlang from '$lib/components/CodeMirrorRainlang.svelte';
  import { subgraphUrl } from '$lib/stores/settings';
  import TanstackPageContentDetail from './TanstackPageContentDetail.svelte';
  import { handleOrderRemoveModal } from '$lib/services/modal';
  import { createQuery } from '@tanstack/svelte-query';
  import { QKEY_ORDER } from '$lib/queries/keys';
  import { orderDetail } from '$lib/queries/orderDetail';
  import OrderTradesListTable from '../tables/OrderTradesListTable.svelte';
  import OrderTradesChart from '../charts/OrderTradesChart.svelte';

  export let id: string;

  $: orderDetailQuery = createQuery({
    queryKey: [QKEY_ORDER + id],
    queryFn: () => {
      return orderDetail(id, $subgraphUrl || '');
    },
    enabled: !!$subgraphUrl,
  });
</script>

<TanstackPageContentDetail query={orderDetailQuery} emptyMessage="Order not found">
  <svelte:fragment slot="top" let:data>
    <div class="flex gap-x-4 text-3xl font-medium dark:text-white">
      <div class="flex gap-x-2">
        <span class="font-light">Order</span>
        <Hash shorten value={data.order.order_hash} />
      </div>
      <BadgeActive active={data.order.active} large />
    </div>
    {#if data.order && $walletAddressMatchesOrBlank(data.order.owner) && data.order.active}
      <Button color="dark" on:click={() => handleOrderRemoveModal(data.order)}>Remove</Button>
    {/if}
  </svelte:fragment>
  <svelte:fragment slot="card" let:data>
    <div class="flex flex-col gap-y-6">
      <CardProperty>
        <svelte:fragment slot="key">Owner</svelte:fragment>
        <svelte:fragment slot="value">
          <Hash type={HashType.Wallet} shorten={false} value={data.order.owner} />
        </svelte:fragment>
      </CardProperty>

      <CardProperty>
        <svelte:fragment slot="key">Created</svelte:fragment>
        <svelte:fragment slot="value">
          {formatTimestampSecondsAsLocal(BigInt(data.order.timestamp_added))}
        </svelte:fragment>
      </CardProperty>

      <CardProperty>
        <svelte:fragment slot="key">Input vaults</svelte:fragment>
        <svelte:fragment slot="value">
          {#each data.order.inputs || [] as t}
            <ButtonVaultLink tokenVault={t} />
          {/each}
        </svelte:fragment>
      </CardProperty>

      <CardProperty>
        <svelte:fragment slot="key">Output vaults</svelte:fragment>
        <svelte:fragment slot="value">
          {#each data.order.outputs || [] as t}
            <ButtonVaultLink tokenVault={t} />
          {/each}
        </svelte:fragment>
      </CardProperty>
    </div>
  </svelte:fragment>
  <svelte:fragment slot="chart">
    <OrderTradesChart {id} />
  </svelte:fragment>
  <svelte:fragment slot="below" let:data>
    <Tabs
      style="underline"
      contentClass="mt-4"
      defaultClass="flex flex-wrap space-x-2 rtl:space-x-reverse mt-4"
    >
      <TabItem open title="Rainlang source">
        {#if data.rainlang}
          <div class="mb-8 overflow-hidden rounded-lg border dark:border-none">
            <CodeMirrorRainlang disabled={true} value={data.rainlang} />
          </div>
        {:else}
          <div class="w-full tracking-tight text-gray-900 dark:text-white">
            Rain source not included in order meta
          </div>
        {/if}
      </TabItem>
      <TabItem title="Trades">
        <OrderTradesListTable {id} />
      </TabItem>
    </Tabs>
  </svelte:fragment>
</TanstackPageContentDetail>
