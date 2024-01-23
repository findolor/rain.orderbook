import { get } from 'svelte/store';
import { invoke } from '@tauri-apps/api';
import { rpcUrl, orderbookAddress, walletDerivationIndex } from './settings';
import { chainId } from '$lib/stores/chain';

function useVaultDepositStore() {
  async function call(vaultId: bigint, token: string, amount: bigint) {
    await invoke("vault_deposit", { 
      depositArgs: { 
        vault_id: vaultId.toString(),
        token,
        amount: amount.toString(),
      }, 
      transactionArgs: { 
        rpc_url: get(rpcUrl),
        orderbook_address: get(orderbookAddress),
        derivation_index: get(walletDerivationIndex),
        chain_id: get(chainId),
        max_priority_fee_per_gas: '400000000000',
        max_fee_per_gas: '400000000000',
      } 
    });
  }

  return {
    call
  }
}

export const vaultDeposit = useVaultDepositStore();