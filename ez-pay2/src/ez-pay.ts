import {
  ChangeRequested as ChangeRequestedEvent,
  ClaimTokens as ClaimTokensEvent,
  CollateralWithdrawn as CollateralWithdrawnEvent,
  EMIPaid as EMIPaidEvent,
  Liquidated as LiquidatedEvent,
  LoanRequested as LoanRequestedEvent,
  LoanTransferred as LoanTransferredEvent,
  RequestAccepted as RequestAcceptedEvent
} from "../generated/EzPay/EzPay"
import {
  ChangeRequested,
  ClaimTokens,
  CollateralWithdrawn,
  EMIPaid,
  Liquidated,
  LoanRequested,
  LoanTransferred,
  RequestAccepted
} from "../generated/schema"

export function handleChangeRequested(event: ChangeRequestedEvent): void {
  let entity = new ChangeRequested(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.borrower = event.params.borrower
  entity.EzPay_id = event.params.id
  entity.notificationToLender = event.params.notificationToLender

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleClaimTokens(event: ClaimTokensEvent): void {
  let entity = new ClaimTokens(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.EzPay_id = event.params.id

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCollateralWithdrawn(
  event: CollateralWithdrawnEvent
): void {
  let entity = new CollateralWithdrawn(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.borrower = event.params.borrower
  entity.token = event.params.token
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleEMIPaid(event: EMIPaidEvent): void {
  let entity = new EMIPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.borrower = event.params.borrower
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleLiquidated(event: LiquidatedEvent): void {
  let entity = new Liquidated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.borrower = event.params.borrower
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleLoanRequested(event: LoanRequestedEvent): void {
  let entity = new LoanRequested(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.requester = event.params.requester
  entity.borrower = event.params.borrower
  entity.EzPay_id = event.params.id

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleLoanTransferred(event: LoanTransferredEvent): void {
  let entity = new LoanTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.borrower = event.params.borrower
  entity.EzPay_id = event.params.id

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRequestAccepted(event: RequestAcceptedEvent): void {
  let entity = new RequestAccepted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.EzPay_id = event.params.id
  entity.user = event.params.user

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
