# iOS SDK example

This iOS dapp is an example of how to connect to Ethereum and make requests using the SDK.
The example requests include:

- [`ConnectView.swift`](metamask-ios-sdk/ConnectView.swift) - Connect to the Ethereum blockchain
  using the SDK.
  The other examples are based on a successful connection as demonstrated in this example.
- [`TransactionView.swift`](metamask-ios-sdk/TransactionView.swift) - Send a transaction.
- [`SignView.swift`](metamask-ios-sdk/SignView.swift) - Sign a transaction.
- [`SwitchChainView.swift`](metamask-ios-sdk/SwitchChainView.swift) - Switch to a different network
  chain (you need to call the
  [`wallet_addEthereumChain`](https://docs.metamask.io/wallet/reference/wallet_addethereumchain/)
  RPC method first if it doesn't already exist in the MetaMask wallet).

To run the example dapp:

1. Make sure you meet the [prerequisites](../README.md#prerequisites).
2. Clone this repository.
3. Change directory to `metamask-ios-sdk/Example`.
4. Run `pod install`.
5. Open `metamask-ios-sdk.xcworkspace` and run the project.
