# MetaMask iOS SDK

Import MetaMask SDK into your native iOS dapp to enable your users to easily connect with their
MetaMask Mobile wallet.

See the [example iOS dapp](Example) and the documentation for
[setting up the SDK in your iOS dapp](https://docs.metamask.io/wallet/how-to/connect/set-up-sdk/mobile/ios/)
for more information.

You can also see the [JavaScript SDK repository](https://github.com/MetaMask/metamask-sdk) and the
[Android SDK repository](https://github.com/MetaMask/metamask-android-sdk).

## Prerequisites

- MetaMask Mobile version 7.6.0 or later installed on your target device (that is, a physical device
  or emulator).
  You can install MetaMask Mobile from the [App Store](https://apps.apple.com/us/app/metamask-blockchain-wallet/id1438144202)
  or clone and compile MetaMask Mobile from [source](https://github.com/MetaMask/metamask-mobile)
  and build to your target device.

- iOS version 14 or later.
  The SDK supports `ios-arm64` (iOS devices) and `ios-arm64-simulator` (M1 chip simulators).
  It currently doesn't support `ios-ax86_64-simulator` (Intel chip simulators).

## Get started

### 1. Install the SDK

#### CocoaPods

To add the SDK as a CocoaPods dependency to your project, add the following entry to our Podfile:

```text
pod 'metamask-ios-sdk'
```

Run the following command:

```bash
pod install
```

#### Swift Package Manager

To add the SDK as a Swift Package Manager (SPM) package to your project, in Xcode, select
**File > Swift Packages > Add Package Dependency**.
Enter the URL of the MetaMask iOS SDK repository: `https://github.com/MetaMask/metamask-ios-sdk`.

Alternatively, you can add the URL directly in your project's package file:

```swift
dependencies: [
    .package(
        url: "https://github.com/MetaMask/metamask-ios-sdk",
        from: "0.4.0"
    )
]
```

### 2. Import the SDK

Import the SDK by adding the following line to the top of your project file:

```swift
import metamask_ios_sdk
```

### 3. Connect your dapp

Connect your dapp to MetaMask by adding the following code to your project file:

```swift
let appMetadata = AppMetadata(name: "Dub Dapp", url: "https://dubdapp.com")

@ObservedObject var metamaskSDK = MetaMaskSDK.shared(appMetadata)

metamaskSDK.connect()
```

By default, MetaMask logs three SDK events: `connectionRequest`, `connected`, and `disconnected`.
This allows MetaMask to monitor any SDK connection issues.
To disable this, set `metamaskSDK.enableDebug = false`.

### 4. Call methods

You can now call any [JSON-RPC API method](https://docs.metamask.io/wallet/reference/eth_subscribe/)
using `metamaskSDK.request()`.

#### Example: Get chain ID

The following example gets the user's chain ID by calling
[`eth_chainId`](https://docs.metamask.io/wallet/reference/eth_chainid/).

```swift
let chainIdRequest = EthereumRequest(method: .ethChainId)
let chainId = await metamaskSDK.request(chainIdRequest)
```

#### Example: Get account balance

The following example gets the user's account balance by calling
[`eth_getBalance`](https://docs.metamask.io/wallet/reference/eth_getbalance/).

```swift

// Create parameters
let account = metamaskSDK.account

let parameters: [String] = [
    account, // account to check for balance
    "latest" // "latest", "earliest" or "pending" (optional)
  ]

// Create request
let getBalanceRequest = EthereumRequest(
    method: .ethGetBalance,
    params: parameters)

// Make request
let accoutBalance = await metamaskSDK.request(getBalanceRequest)
```

#### Example: Send transaction

The following example sends a transaction by calling
[`eth_sendTransaction`](https://docs.metamask.io/wallet/reference/eth_sendtransaction/).

**Use a dictionary**

If your request parameters make up a simple dictionary of string key-value pairs, you can use the
dictionary directly.
Note that `Any` or even `AnyHashable` types aren't supported, since the type must be explicitly known.

```swift
// Create parameters
let account = metamaskSDK.account

let parameters: [String: String] = [
    "to": "0x...", // receiver address
    "from": account, // sender address
    "value": "0x..." // amount
  ]

// Create request
let transactionRequest = EthereumRequest(
    method: .ethSendTransaction,
    params: [parameters] // eth_sendTransaction expects an array parameters object
    )

// Make a transaction request
let transactionResult = await metamaskSDK.request(transactionRequest)
```

**Use a struct**

For more complex parameter representations, define and use a struct that conforms to `CodableData`,
that is, implements the following requirement:

```
func socketRepresentation() -> NetworkData
```

The type can then be represented as a socket packet.

```swift
struct Transaction: CodableData {
    let to: String
    let from: String
    let value: String
    let data: String?

    init(to: String, from: String, value: String, data: String? = nil) {
        self.to = to
        self.from = from
        self.value = value
        self.data = data
    }

    func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value,
            "data": data
        ]
    }
}

// Create parameters
let account = metamaskSDK.account

let transaction = Transaction(
    to: "0x...", // receiver address
    from: account, // sender address
    value: "0x..." // amount
)

// Create request
let transactionRequest = EthereumRequest(
    method: .ethSendTransaction,
    params: [transaction] // eth_sendTransaction expects an array parameters object
    )

// Make a transaction request
let result = await metamaskSDK.request(transactionRequest)
```
#### Example: Send chained rpc (batch) requests
```swift

// Create parameters
let account = metamaskSDK.account

let params1: [String] = [account, "Message 1"]
let params2: [String] = [account, "Message 2"]
let params3: [String] = [account, "Message 3"]

let signRequest1 = EthereumRequest(
    method: .personalSign,
    params: params1
)

let signRequest2 = EthereumRequest(
    method: .personalSign,
    params: params2
)

let signRequest3 = EthereumRequest(
    method: .personalSign,
    params: params3
)

let requestBatch: [EthereumRequest] = [signRequest1, signRequest2, signRequest3]

let result = await metamaskSDK.batchRequest(requestBatch)
```
