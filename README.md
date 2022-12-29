# MetaMask iOS SDK
MetaMask iOS SDK is a library that enables developers to run decentralised applications (Dapps) as native iOS applications.

## How it works
You can import the MetaMask iOS SDK into your iOS application to enable users to easily connect with their MetaMask Mobile wallet.

### 1. Install

#### Cocoapods
To add MetaMask iOS SDK as a cocoapods dependency to your project, add this entry in your Podfile: 
```
  pod 'metamask-ios-sdk'
```
And then run:
```
pod install
```
#### Swift Package Manager
To add MetaMask iOS SDK as an SPM package to your project, in Xcode select: `File -> Swift Packages -> Add Package Dependency`.

And then enter this repository's url, i.e https://github.com/MetaMask/metamask-ios-sdk. Now you can import the SDK:
```
import metamask_ios_sdk
```
#### Note
Please note that the SDK currently supports the following architectures 
- `aarch64-apple-ios` (iOS devices) and 
- `x86_64-apple-ios` (Intel Mac-based simulators)

We currently do not support `aarch64-apple-ios-sim` (M1 or Apple Silicon simulators). However, you should be able run it on an M1 simulator by setting your Xcode to open in Rosetta mode. This can be done by going to the location `/Applications/`, right click on `Xcode -> Get Info -> check the option "Open using Rosetta"`. This effectively runs Xcode in Intel mode.

### 2. Import the SDK
```
import metamask_ios_sdk
```

### 3. Connect your Dapp
```
@ObservedObject var ethereum = MMSDK.shared.ethereum

// We log three events: connection request, connected, disconnected, otherwise no tracking. 
// This helps us to monitor any SDK connection issues. 
//  

let dappMetaData = DappMetadata(name: "myapp", url: "myapp.com")

// This is the same as calling "eth_requestAccounts"
ethereum.connect(dappMetaData)
```

We log three SDK events: `connectionRequest`, `connected` and `disconnected`. Otherwise no tracking. This helps us to monitor any SDK connection issues. If you wish to disable this, you can do so by setting `MMSDK.shared.enableDebug = false`.


### 4. You can now call any ethereum provider method
We use Combine to publish ethereum events, so you'll need an `AnyCancellable` storage.
```
@State private var cancellables: Set<AnyCancellable> = []
```
#### Example 1: Get `eth_chainId`
```
@State var chainID: String?

let chainIdRequest = EthereumRequest(method: .ethChainId)

ethereum.request(chainIdRequest)?.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print("\(error.localizedDescription)")
    default: break
    }
}, receiveValue: { chainId in
    self.chainID = chainId
})
.store(in: &cancellables)  
```

#### Example 2: Send transaction
```
// Create a transaction
let transaction = Transaction(
    to: "0x...",
    from: ethereum.selectedAddress,
    value: "0x...")
    
// Create a request
let transactionRequest = EthereumRequest(
    method: .sendTransaction,
    params: [transaction])

// Send a transaction request
ethereum.request(chainItransactionRequestdRequest)?.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print("\(error.localizedDescription)")
    default: break
    }
}, receiveValue: { result in
    print(result)
})
.store(in: &cancellables)  
```

#### Example 3: Custom requests
To create your own requests, you can use a primitive key-pair data type dictionary object or use a struct that conforms to `CodableData` i.e implementing the `func socketRepresentation() -> NetworkData` requirement, so that the type can be represented as a socket packet.
```
let params: [String: String] = [
    "to": "0x...", // receiver address
    "from": ethereum.selectedAddress, // or any sender address
    "value": "0x..." // amount
  ]
  
let request = EthereumRequest(
    method: .sendTransaction,
    params: [params])

ethereum.request(request)
```
OR
```
public struct SendTransaction: CodableData {
    public var to: String
    public let from: String
    public var value: String
    
    public init(to: String, from: String, value: String) {
        self.to = to
        self.from = from
        self.value = value
    }
    
    public func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value
        ]
    }
}
```
Then use struct object as shown in [Example 2](#example-2-send-transaction) above

## Examples
We have created an [Example](./Example/) project as a guide on how to connect to ethereum and make requests. There are three illustrated examples:

a) `ConnectView.swift` - How to connect to the ethereum blockchain via the MetaMask SDK. The other examples are based on a successful connection as demonstrated in this example

b) `TransactionView.swift` - How to send a transaction

c) `SignView.swift` - How to sign a transaction

To run the example project, clone this repository, change directory to `metamask-ios-sdk/Example`, and then run `pod install` from the Example directory to install the SDK as a dependency on the project, and then open the `metamask-ios-sdk.xcworkspace`

## Requirements
This SDK has an iOS minimum version requirement of 14.0. You need your app to have an iOS minimum deployment of no less than 14.0.
