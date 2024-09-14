//
//  NSRecursiveLock.swift
//

import Foundation

extension NSRecursiveLock {
  @inlinable @discardableResult
  func sync<Value>(_ work: () -> Value) -> Value {
    lock()
    defer { unlock() }
    return work()
  }
}
