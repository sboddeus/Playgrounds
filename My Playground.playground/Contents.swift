import Foundation
import UIKit

// Below illustrates more clearly the dos and donts of structs and mutating fu

struct Mine {
    let value = 12
    var otherValue = 13
    
    mutating func increase(byValue: Int) {
        otherValue += byValue
    }
    
//      mutating func inscreaseValue(byValue: Int) {
//          value += byValue
//      }
}


let invalidInstanceOne = Mine()
// invalidInstanceOne.increase(byValue: 12)

var instanceOne = Mine()
print(instanceOne.otherValue)
instanceOne.increase(byValue: 10)
print(instanceOne.otherValue)

let copyInstanceOne = instanceOne
// copyInstanceOne.increase(byValue: 10)
print(copyInstanceOne.otherValue)

var validCopyInstanceOne = instanceOne
validCopyInstanceOne.increase(byValue: 13)
print(validCopyInstanceOne.otherValue)
print(instanceOne.otherValue)


extension String {
    func versionToInt() -> [Int] {
        return self.components(separatedBy: ".").map { Int.init($0) ?? 0 }
    }
}

print("cat".versionToInt().lexicographicallyPrecedes("bob".versionToInt()))



// Super fun observable stuff

class Observable {
    func subscribe(_ subscriber: () -> Void) {
        
    }
    
    func unsubscribe(_ token: String) {
        
    }
    
    func update(_ value: Int) {
        
    }
}


protocol StrictObservable {
    func subscribe(_ subscriber: () -> Void)
    func unsubscribe(_ token: String)
}

extension Observable: StrictObservable {}

struct MyStruct {
    let sub: StrictObservable
    private let obs: Observable
    
    init() {
        let thing = Observable()
        sub = thing
        obs = thing
    }
}


protocol CSViewControllerTitle {
    var csTitle: String { get }
}

class MyVC: UIViewController, CSViewControllerTitle {
    var csTitle: String = ""
}

extension UIViewController {
    var analyticsTitle: String {
        if let cvc = self as? CSViewControllerTitle {
            return cvc.csTitle
        } else {
            return ""
        }
    }
}
