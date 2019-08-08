
import CwlCore
import CwlSignals
import UIKit


public protocol CodableContainer: Lifetime, Codable {
    var codableValueChanged: Signal<Void> { get }
    var childCodableContainers: [CodableContainer] { get }
}

extension CodableContainer {
    public var childCodableContainers: [CodableContainer] {
        return Mirror(reflecting: self).children.compactMap { $0.value as? CodableContainer }
    }
    
    public var codableValueChanged: Signal<Void> {
        let sequence = childCodableContainers.map { return $0.codableValueChanged }
        if sequence.isEmpty {
            return Signal<Void>.preclosed()
        } else if sequence.count == 1 {
            return sequence.first!
        } else {
            return Signal<Void>.merge(sequence: sequence)
        }
    }
    
    public mutating func cancel() {
        for var v in childCodableContainers {
            v.cancel()
        }
    }
}

extension Array: Lifetime where Element: CodableContainer {
    public mutating func cancel() {
        for var v in self {
            v.cancel()
        }
    }
}

extension Optional: Lifetime where Wrapped: CodableContainer {
    public mutating func cancel() {
        self?.cancel()
    }
}

extension Array: CodableContainer where Element: CodableContainer {
    public var childCodableContainers: [CodableContainer] {
        return flatMap { $0.childCodableContainers }
    }
}

extension Optional: CodableContainer where Wrapped: CodableContainer {
    public var childCodableContainers: [CodableContainer] {
        return self?.childCodableContainers ?? []
    }
}
