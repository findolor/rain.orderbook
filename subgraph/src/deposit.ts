import { Deposit } from "../generated/OrderBook/OrderBook";
import { Deposit as DepositEntity } from "../generated/schema";
import { createTransactionEntity } from "./transaction";

export function handleDeposit(event: Deposit): void {
  createDepositEntity(event);
}

export function createDepositEntity(event: Deposit): void {
  let deposit = new DepositEntity(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString()
  );
  deposit.amount = event.params.amount;
  deposit.sender = event.params.sender;
  deposit.vaultId = event.params.vaultId;
  deposit.token = event.params.token;
  deposit.transaction = createTransactionEntity(event);
  deposit.save();
}
