import UIKit
import CoreData
import PlaygroundSupport

let page = PlaygroundPage.current
page.needsIndefiniteExecution = true

let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
containerView.backgroundColor = .green

class Thingy {}

class SubThingy: Thingy {}

let thing: (Thingy) -> Bool = { $0 as? SubThingy != nil }

let numbers = [1,2,3,4,5,6,7,8,9,10,11]
let evens = numbers.filter { $0 % 2 == 0 }


let squareLabel = UILabel(frame: CGRect(x: 100, y: 0, width: 100, height: 100))
squareLabel.text = "HELLO!"
let blurEffect = UIBlurEffect(style: .dark)
let blurView = UIVisualEffectView(effect: blurEffect)
let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
blurView.contentView.addSubview(vibrancyView)
vibrancyView.contentView.addSubview(squareLabel)

blurView.frame = CGRect(x: 98, y: 0, width: 100, height: 100)

let purple = UIView(frame: CGRect(x: 250, y: 0, width: 100, height: 100))
purple.backgroundColor = .purple

containerView.addSubview(blurView)
containerView.addSubview(purple)

let animator = UIDynamicAnimator(referenceView: containerView)
let gravity = UIGravityBehavior(items: [blurView, purple])
animator.addBehavior(gravity)

let barrier = UIView(frame: CGRect(x: 0, y: 300, width: 140, height: 20))
barrier.backgroundColor = .red
containerView.addSubview(barrier)
barrier.alignmentRect(forFrame: barrier.frame)

let collision = UICollisionBehavior(items: [blurView, purple])
collision.translatesReferenceBoundsIntoBoundary = true
animator.addBehavior(collision)

let attached = UIAttachmentBehavior(item: blurView, attachedTo: purple)
animator.addBehavior(attached)
//  
//  let otherAttached = UIAttachmentBehavior(item: barrier, attachedTo: purple)
//  animator.addBehavior(otherAttached)

let rightEdge = CGPoint(x: barrier.frame.origin.x + barrier.frame.size.width, y: barrier.frame.origin.y)
// collision.addBoundaryWithIdentifier("barrier", fromPoint: barrier.frame.origin, toPoint: rightEdge)
collision.addBoundary(withIdentifier: "barrier" as NSCopying, from: barrier.frame.origin, to: rightEdge)

PlaygroundPage.current.liveView = containerView

print("\(Thread.current)")

let group1 = DispatchGroup()
group1.enter()
DispatchQueue(label: "background", qos: .background).async {
    print("\(Thread.current)")
    group1.leave()
}

let group2 = DispatchGroup()
group2.enter()
DispatchQueue(label: "utility", qos: .utility).async {
    print("\(Thread.current)")
    group2.leave()
}
//  DispatchQueue(label: "background", qos: .background).sync {
//      print("\(Thread.current)")
//  }
// Core Data Stuff

class DataController: NSObject {
    var persistentContainer: NSPersistentContainer
    init(completionClosure: @escaping () -> ()) {
        persistentContainer = NSPersistentContainer(name: "DataModel")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionClosure()
        }
    }
}

class Employee: NSManagedObject {
    @NSManaged var name: String?
}
let group = DispatchGroup()
group.enter()
//  let moc = DataController(completionClosure:  { 
//      group.leave()
//  })

group.notify(queue: .main) {
    //let employee = NSEntityDescription.insertNewObjectForEntityForName("Employee", inManagedObjectContext: moc.persistentContainer.managedObjectModel)
    
}


