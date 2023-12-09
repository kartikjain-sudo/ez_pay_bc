import { newMockEvent } from "matchstick-as"
import { ethereum, Address, Bytes, BigInt } from "@graphprotocol/graph-ts"
import {
  ChangeRequested,
  ClaimTokens,
  CollateralWithdrawn,
  EMIPaid,
  Liquidated,
  LoanRequested,
  LoanTransferred,
  RequestAccepted
} from "../generated/EzPay/EzPay"

export function createChangeRequestedEvent(
  lender: Address,
  borrower: Address,
  id: Bytes,
  notificationToLender: boolean
): ChangeRequested {
  let changeRequestedEvent = changetype<ChangeRequested>(newMockEvent())

  changeRequestedEvent.parameters = new Array()

  changeRequestedEvent.parameters.push(
    new ethereum.EventParam("lender", ethereum.Value.fromAddress(lender))
  )
  changeRequestedEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromAddress(borrower))
  )
  changeRequestedEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  changeRequestedEvent.parameters.push(
    new ethereum.EventParam(
      "notificationToLender",
      ethereum.Value.fromBoolean(notificationToLender)
    )
  )

  return changeRequestedEvent
}

export function createClaimTokensEvent(id: Bytes): ClaimTokens {
  let claimTokensEvent = changetype<ClaimTokens>(newMockEvent())

  claimTokensEvent.parameters = new Array()

  claimTokensEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )

  return claimTokensEvent
}

export function createCollateralWithdrawnEvent(
  borrower: Address,
  token: Address,
  amount: BigInt
): CollateralWithdrawn {
  let collateralWithdrawnEvent = changetype<CollateralWithdrawn>(newMockEvent())

  collateralWithdrawnEvent.parameters = new Array()

  collateralWithdrawnEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromAddress(borrower))
  )
  collateralWithdrawnEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  collateralWithdrawnEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return collateralWithdrawnEvent
}

export function createEMIPaidEvent(borrower: Address, amount: BigInt): EMIPaid {
  let emiPaidEvent = changetype<EMIPaid>(newMockEvent())

  emiPaidEvent.parameters = new Array()

  emiPaidEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromAddress(borrower))
  )
  emiPaidEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return emiPaidEvent
}

export function createLiquidatedEvent(
  lender: Address,
  borrower: Address,
  amount: BigInt
): Liquidated {
  let liquidatedEvent = changetype<Liquidated>(newMockEvent())

  liquidatedEvent.parameters = new Array()

  liquidatedEvent.parameters.push(
    new ethereum.EventParam("lender", ethereum.Value.fromAddress(lender))
  )
  liquidatedEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromAddress(borrower))
  )
  liquidatedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return liquidatedEvent
}

export function createLoanRequestedEvent(
  requester: Address,
  borrower: boolean,
  id: Bytes
): LoanRequested {
  let loanRequestedEvent = changetype<LoanRequested>(newMockEvent())

  loanRequestedEvent.parameters = new Array()

  loanRequestedEvent.parameters.push(
    new ethereum.EventParam("requester", ethereum.Value.fromAddress(requester))
  )
  loanRequestedEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromBoolean(borrower))
  )
  loanRequestedEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )

  return loanRequestedEvent
}

export function createLoanTransferredEvent(
  lender: Address,
  borrower: Address,
  id: Bytes
): LoanTransferred {
  let loanTransferredEvent = changetype<LoanTransferred>(newMockEvent())

  loanTransferredEvent.parameters = new Array()

  loanTransferredEvent.parameters.push(
    new ethereum.EventParam("lender", ethereum.Value.fromAddress(lender))
  )
  loanTransferredEvent.parameters.push(
    new ethereum.EventParam("borrower", ethereum.Value.fromAddress(borrower))
  )
  loanTransferredEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )

  return loanTransferredEvent
}

export function createRequestAcceptedEvent(
  id: Bytes,
  user: Address
): RequestAccepted {
  let requestAcceptedEvent = changetype<RequestAccepted>(newMockEvent())

  requestAcceptedEvent.parameters = new Array()

  requestAcceptedEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromFixedBytes(id))
  )
  requestAcceptedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )

  return requestAcceptedEvent
}
