
import Foundation
import UIKit

// MARK: - Hierarchy navigation

struct SuperviewsIterator: IteratorProtocol {
    
    public typealias Element = UIView
    private var currentView: UIView?
    
    init(startView: UIView) {
        self.currentView = startView.superview
    }
    
    public mutating func next() -> UIView? {
        defer {
            currentView = currentView?.superview
        }
        return currentView
    }
}

struct SuperviewsSequence: Sequence {
    
    let startView: UIView
    
    func makeIterator() -> SuperviewsIterator {
        return SuperviewsIterator(startView: startView)
    }
}

struct SubviewsInOrderIterator: IteratorProtocol {
    
    public typealias Element = UIView
    private var currentView: UIView?
    
    private var sequenceQueue: [UIView]
    
    init(startView: UIView) {
        self.currentView = startView
        sequenceQueue = [startView]
    }
    
    public mutating func next() -> UIView? {
        currentView = sequenceQueue.first
        
        if let view = currentView {
            sequenceQueue.remove(at: 0)
            sequenceQueue.append(contentsOf: view.subviews)
        }
        
        return currentView
    }
    
}

extension UIView {
    
    var superviews: SuperviewsSequence {
        return SuperviewsSequence(startView: self)
    }
    
    func firstSuperview(where predicate: (UIView) -> Bool) -> UIView? {
        return ([self] + superviews).first(where: predicate)
    }
    
    func lastSuperview(where predicate: (UIView) -> Bool) -> UIView? {
        return ([self] + superviews).last(where: predicate)
    }
    
    func subviews(where predicate: (UIView) -> Bool) -> [UIView] {
        let views: [UIView] = predicate(self) ? [self] : []
        return views + subviews.flatMap { $0.subviews(where: predicate) }
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// MARK: - Identifying and describing views

protocol RecyclingListCell: UIView {
    
    var indexInList: Int? { get }
}

extension UITableViewCell: RecyclingListCell {
    
    var indexInList: Int? {
        guard let list = superview as? UITableView, let indexPath = list.indexPath(for: self) else { return nil }
        return (0..<indexPath.section).map(list.numberOfRows(inSection:)).reduce(0, +) + indexPath.row
    }
}

extension UICollectionViewCell: RecyclingListCell {
    
    var indexInList: Int? {
        guard let list = superview as? UICollectionView, let indexPath = list.indexPath(for: self) else { return nil }
        return (0..<indexPath.section).map(list.numberOfItems(inSection:)).reduce(0, +) + indexPath.item
    }
}

extension UITableView {
    
    static var headerKind: String {
        return "UITableViewHeader"
    }
    
    static var footerKind: String {
        return "UITableViewFooter"
    }
}

extension UITableViewHeaderFooterView {
    
    var uniqueDescriptorInTable: String? {
        guard let table = superview as? UITableView, let paths = table.indexPathsForVisibleRows else { return nil }
        var sections = Set(paths.map { $0.section })
        guard let max = sections.max(), let min = sections.min() else { return nil }
        // In some edge cases, there is no cell onscreen of the same section than the header or footer being tapped,
        // this is why we add these sections
        sections.insert(max + 1)
        sections.insert(min - 1)
        if let headerIndex = (sections.first { table.headerView(forSection: $0) === self }) {
            return getDescriptor(forKind: UITableView.headerKind, andIndex: headerIndex)
        }
        if let footerIndex = (sections.first { table.footerView(forSection: $0) === self }) {
            return getDescriptor(forKind: UITableView.footerKind, andIndex: footerIndex)
        }
        return nil
    }
}

extension UICollectionReusableView {
    
    var uniqueDescriptorInCollection: String? {
        // Only intended for supplementary and decoration views, not cells. First because it doesn't work with cells,
        // second because it causes a layout computation and shouldn't be called too often in case it hurts performance
        if self is UICollectionViewCell { return nil }
        guard let collection = superview as? UICollectionView else { return nil }
        let smallestRectangleOnSelf = CGRect(origin: center, size: CGSize(width: 1, height: 1))
        let attributes = collection.collectionViewLayout.layoutAttributesForElements(in: smallestRectangleOnSelf)?[0]
        guard let attr = attributes else { return nil }
        let kind = attr.representedElementKind ?? className
        return getDescriptor(forKind: kind, andIndex: attr.indexPath.section)
    }
}

extension UIView {
    
    var className: String {
        return String(describing: type(of: self))
    }
    
    func getDescriptor(forKind kind: String, andIndex index: Int) -> String {
        return "\(kind):eq(\(index))"
    }
    
    var viewLayerIndexInSuperview: Int {
        return self.superview?.subviews.firstIndex { $0 == self } ?? 0
    }
    
    var defaultDescriptorInSuperview: String {
        return getDescriptor(forKind: className, andIndex: viewLayerIndexInSuperview)
    }
    
    // In the Zone Exposure PoC colleciton view reusable footers and
    // table view headers were causing an odd crash in their self.uniqueDescriptorIn...'s
    // to temporarily fix the issue I removed them.
    // They also seem to be very performance sensitive (see their definition).
    // In a production implementation these issues would need to be further investigated.
    public var uniqueDescriptorInSuperview: String {
        switch self {
        case let self as RecyclingListCell:
            guard let index = self.indexInList else { return defaultDescriptorInSuperview }
            return getDescriptor(forKind: className, andIndex: index)
        case let self as UICollectionReusableView:
            return defaultDescriptorInSuperview
        //return self.uniqueDescriptorInCollection ?? defaultDescriptorInSuperview
        case let self as UITableViewHeaderFooterView:
            return defaultDescriptorInSuperview
        //return self.uniqueDescriptorInTable ?? defaultDescriptorInSuperview
        default:
            return defaultDescriptorInSuperview
        }
    }
    
    var viewToRootPath: String {
        let descriptors = ([self] + superviews).reversed().map { $0.uniqueDescriptorInSuperview }
        return (["[root]"] + descriptors).joined(separator: ">")
    }
    
    var viewId: String {
        if let restorationId = self.restorationIdentifier { // swiftlint:disable:this id_instead_of_identifier
            return restorationId
        } else if tag != 0 {
            return "\(self.className)_\(tag)"
        } else {
            return "\(self.className)_\(self.viewToRootPath.hash)"
        }
    }
    
    func firstCustomView() -> UIView {
        var viewInOrder = SubviewsInOrderIterator(startView: self)
        
        var bailCount = 20
        while let next = viewInOrder.next(), bailCount != 0 {
            if Bundle(for: type(of: next)) == Bundle.main {
                return next
            }
            bailCount -= 1
        }
        
        return self
    }
    
    func viewURL(withTitle title: String?) -> String {
        let firstCustomViewType = type(of: firstCustomView())
        if let parent = parentViewController {
            let encodedTitle = title?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? title
            let query: String
            if let encodedTitle = encodedTitle {
                query = "?title=\(encodedTitle)"
            } else {
                query = ""
            }
            return "/\(type(of: parent))/\(firstCustomViewType)\(query)"
        } else {
            // We don't really expect this to happen very often
            return "/root/\(firstCustomViewType)"
        }
    }
    
    var viewURL: String {
        if let parent = parentViewController,
            let title = parent.title,
            !title.isEmpty {
            return viewURL(withTitle: title)
        }
        return viewURL(withTitle: nil)
    }
}

// MARK: - Miscellaneous extensions

extension UIView {
    
    var parentOrTypeTitle: String {
        if let parent = parentViewController {
            let title = parent.title
            return title ?? "\(type(of: parent))"
        }
        
        return "\(type(of: self))"
    }
    
    func isVisibleInView(_ referenceView: UIView) -> Bool {
        guard let superview = self.superview else {
            return false
        }
        
        let viewFrame = superview == referenceView ?
            frame :
            superview.convert(frame, to: referenceView)
        
        return referenceView.bounds.intersects(viewFrame)
    }
    
    func startRotating(duration: CFTimeInterval = 0.5, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        if self.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: .pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        self.layer.add(animation, forKey: "transform.rotation.z")
    }
    
    func stopRotating() {
        self.layer.removeAnimation(forKey: "transform.rotation.z")
    }
}
