# MetaMask iOS SDK
MetaMask iOS SDK is a library that enables developers to run decentralised applications (Dapps) as native iOS applications.

## How it works
You can import the MetaMask iOS SDK into your iOS application to enable users to easily connect with their MetaMask Mobile wallet.

### 1. Install
Add MetaMask iOS SDK as a cocoapods dependency to your project 
```
  pod 'metamask-ios-sdk'
```
### 2. Import the SDK
```
import metamask_ios_sdk
```

### 3. Connect your Dapp
```
@ObservedObject var ethereum = Ethereum.shared
let dappMetaData = DappMetadata(name: "myapp", url: "myapp.com")

// This is the same as calling "eth_requestAccounts"
ethereum.connect(dappMetaData)
```
### 4. You can now call any ethereum provider method
#### 4.1 Get `eth_chainId`
let chainIdRequest = EthereumRequest(method: .ethChainId)
ethereum.request(chainIdRequest)

#### 4.2 Send Transaction
```
// Create a transaction
let transaction = Transaction(
    to: "0x...",
    from: ethereum.selectedAddress,
    value: "0x...")
    
// Create transaction request
let transactionRequest = EthereumRequest(
    method: .sendTransaction,
    params: [transaction])

// Make send transaction request
ethereum.request(transactionRequest)    
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

metamask-ios-sdk is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'metamask-ios-sdk'
```
