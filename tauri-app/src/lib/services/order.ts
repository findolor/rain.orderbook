import { get } from 'svelte/store';
import { invoke } from '@tauri-apps/api';
import { rpcUrl, orderbookAddress, chainId, subgraphUrl } from '$lib/stores/settings';
import { ledgerWalletDerivationIndex } from '$lib/stores/wallets';
import type { Deployment } from '$lib/typeshare/config';

export async function orderAdd(dotrain: string, deployment: Deployment) {
  await invoke("order_add", {
    dotrain,
    deployment,
    transactionArgs: {
      rpc_url: get(rpcUrl),
      orderbook_address: get(orderbookAddress),
      derivation_index: get(ledgerWalletDerivationIndex),
      chain_id: get(chainId),
    },
  });
}

export async function orderRemove(id: string) {
  await invoke("order_remove", {
    id,
    transactionArgs: {
      rpc_url: get(rpcUrl),
      orderbook_address: get(orderbookAddress),
      derivation_index: get(ledgerWalletDerivationIndex),
      chain_id: get(chainId),
    },
    subgraphArgs: {
      url: get(subgraphUrl)
    }
  });
}

export async function orderAddCalldata(dotrain: string, deployment: Deployment) {
  return await invoke("order_add_calldata", {
    dotrain,
    deployment,
    transactionArgs: {
      rpc_url: get(rpcUrl),
      orderbook_address: get(orderbookAddress),
      derivation_index: get(ledgerWalletDerivationIndex),
      chain_id: get(chainId),
    },
  });
}

export async function orderRemoveCalldata(id: string) {
  return await invoke("order_remove_calldata", {
    id,
    subgraphArgs: {
      url: get(subgraphUrl)
    }
  });
}

export async function orderAddComposeRainlang(dotrain: string, deployment: Deployment): Promise<string> {
  return await invoke("compose_to_rainlang", {
    dotrain,
    deployment,
  });
}