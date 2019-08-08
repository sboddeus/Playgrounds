
import CwlSignals
import CwlCore
import Foundation

/// This enum is intended to be embedded in an ArrayMutation<Element>. The ArrayMutation<Element> combines an IndexSet with this enum. This enum specifies what actions should be taken at the locations specified by the IndexSet.
///
/// 
public enum IndexedMutationKind {
    /// The values at the locations specified by the IndexSet should be deleted.
    /// NOTE: the IndexSet specifies the indexes *before* deletion (and must therefore be applied in reverse).
    case delete
    
    /// The associated Array<Element> contains values that should be inserted such that they have the indexes specified in IndexSet. The Array<Element> and IndexSet must have identical counts.
    /// NOTE: the IndexSet specifies the indexes *after* insertion (and must therefore be applied in forward order).
    case insert
    
    /// Elements are deleted from one end and inserted onto the other. If `Int` is positive, values are deleted from the `startIndex` end and inserted at the `endIndex` end, if `Int` is negative, value are deleted from the `endIndex` end and inserted at the `startIndex`end.
    /// The magnitude of `Int` specifies the number of deleted rows and the sign specified the end.
    /// The Array<Element> contains values that should be inserted at the other end of the collection.
    /// The IndexSet contains the indexes of any revealed (scrolled into view) rows
    case scroll(Int)
    
    /// The associated Array<Element> contains updated values at locations specified by the IndexSet. Semantically, the item should be modelled as updated but not replaced. The Array<Element> and IndexSet must have identical counts.
    // In many cases, update and replace are the same. The only differences relate to scenarios where the items are considered to have "identity". An update *retains* the previous identity whereas a replace *discards* any previous identity.
    case update
    
    /// The values at the locations specified by the IndexSet should be removed from their locations and spliced back in at the location specified by the associated Int index. For scrolled subranges, items may not be moved from outside or to outside the visible range (items moved from outside the visible range must be inserted and items moved outside the visible range must be deleted)
    /// NOTE: the IndexSet specifies the indexes *before* removal (and must therefore be applied in reverse) and the Int index specifies an index *after* removal.
    case move(Int)
    
    /// Equivalent to a Deletion of all previous indexes and an Insertion of the new values. The associated Array<Element> contains the new state of the array. All previous values should be discarded and the entire array replaced with this new version. The Array<Element> and IndexSet must have identical counts.
    /// NOTE: the IndexSet specifies the indexes *after* insertion (and must therefore be applied in forward order).
    case reload
}

/// An `ArrayMutation` communicates changes to an array in one context so that another array, mirroring its contents in another context, can mimic the same changes.
/// Subscribing to a stream of `ArrayMutation`s is sufficient to communication the complete state and animatable transitions of an array between to parts of a program.
/// In most cases, the source and destination will need to keep their own complete copy of the array to correctly calculate the effect of the mutation.
public struct IndexedMutation<Element, Metadata>: ExpressibleByArrayLiteral {
    /// Determines the meaning of this `ArrayMutation`
    public let kind: IndexedMutationKind
    
    /// The metadats type is typically `Void` for plain array mutations since application of an indexed mutation to an array leaves no storage for metadata.
    /// Subrange and tree mutations use the metadata for subrange details and "leaf" data but require specialized storage structures to receive that data. The semantics of the metadata is specific to the respective `apply` functions.
    /// NOTE: Any non-nil metadata is typically set buy the mutation but a metadata value of `nil` doesn't clear the metadata, it usually just has no effect. The exception is `.reload` operations which function like re-creating the storage and explicitly set the value in all cases.
    public let metadata: Metadata?
    
    /// The meaning of the indexSet is dependent on the `kind` – it may contain indexes in the array that will be deleted by this mutation or it may contain indexes that new entries will occupy after application of this mutation.
    public let indexSet: IndexSet
    
    /// New values that will be inserted at locations determined by the `kind` and the `indexSet`.
    public let values: Array<Element>
    
    /// Construct from components.
    public init(kind: IndexedMutationKind, metadata: Metadata?, indexSet: IndexSet, values: Array<Element>) {
        self.kind = kind
        self.metadata = metadata
        self.indexSet = indexSet
        self.values = values
    }
}

public extension IndexedMutation {
    /// Construct an empty array mutation that represents a no-op.
    init() {
        self.init(kind: .update, metadata: nil, indexSet: IndexSet(), values: [])
    }
    
    /// A .reload mutation can be constructed from an array literal (since it is equivalent to an array assignment).
    init(arrayLiteral elements: Element...) {
        self.init(kind: .reload, metadata: nil, indexSet: IndexSet(integersIn: elements.indices), values: elements)
    }
    
    /// Construct a mutation that discards any previous history and simply starts with a completely new array.
    init(metadata: Metadata? = nil, reload values: Array<Element>) {
        self.init(kind: .reload, metadata: metadata, indexSet: IndexSet(integersIn: values.indices), values: values)
    }
    
    /// Construct a mutation that represents a metadata-only change.
    init(metadata: Metadata) {
        self.init(kind: .update, metadata: metadata, indexSet: IndexSet(), values: [])
    }
    
    /// Construct a mutation that represents the deletion of the values at a set of indices.
    init(metadata: Metadata? = nil, deletedIndexSet: IndexSet) {
        self.init(kind: .delete, metadata: metadata, indexSet: deletedIndexSet, values: [])
    }
    
    /// Construct a mutation that represents advancing the visible window through a larger array.
    init(metadata: Metadata? = nil, scrollForwardRevealing indexSet: IndexSet, values: Array<Element>) {
        precondition(indexSet.count == values.count)
        self.init(kind: .scroll(indexSet.count), metadata: metadata, indexSet: indexSet, values: values)
    }
    
    /// Construct a mutation that represents retreating the visible window through a larger array.
    init(metadata: Metadata? = nil, scrollBackwardRevealing indexSet: IndexSet, values: Array<Element>) {
        precondition(indexSet.count == values.count)
        self.init(kind: .scroll(-indexSet.count), metadata: metadata, indexSet: indexSet, values: values)
    }
    
    /// Construct a mutation that represents the insertion of a number of values at a set of indices. The count of indices must match the count of values.
    init(metadata: Metadata? = nil, insertedIndexSet: IndexSet, values: Array<Element>) {
        precondition(insertedIndexSet.count == values.count)
        self.init(kind: .insert, metadata: metadata, indexSet: insertedIndexSet, values: values)
    }
    
    /// Construct a mutation that represents the insertion of a number of values at a set of indices. The count of indices must match the count of values.
    init(metadata: Metadata? = nil, updatedIndexSet: IndexSet, values: Array<Element>) {
        precondition(updatedIndexSet.count == values.count)
        self.init(kind: .update, metadata: metadata, indexSet: updatedIndexSet, values: values)
    }
    
    /// Construct a mutation that represents the insertion of a number of values at a set of indices. The count of indices must match the count of values.
    init(metadata: Metadata? = nil, movedIndexSet: IndexSet, targetIndex: Int) {
        self.init(kind: .move(targetIndex), metadata: metadata, indexSet: movedIndexSet, values: [])
    }
    
    
    /// Convenience constructor for deleting a single element
    static func deleted(at index: Int) -> IndexedMutation<Element, Metadata> {
        return IndexedMutation<Element, Metadata>(deletedIndexSet: IndexSet(integer: index))
    }
    
    /// Convenience constructor for inserting a single element
    static func inserted(_ value: Element, at index: Int) -> IndexedMutation<Element, Metadata> {
        return IndexedMutation<Element, Metadata>(insertedIndexSet: IndexSet(integer: index), values: [value])
    }
    
    /// Convenience constructor for inserting a single element
    static func updated(_ value: Element, at index: Int) -> IndexedMutation<Element, Metadata> {
        return IndexedMutation<Element, Metadata>(updatedIndexSet: IndexSet(integer: index), values: [value])
    }
    
    /// Convenience constructor for inserting a single element
    static func moved(from oldIndex: Int, to newIndex: Int) -> IndexedMutation<Element, Metadata> {
        return IndexedMutation<Element, Metadata>(movedIndexSet: IndexSet(integer: oldIndex), targetIndex: newIndex)
    }
    
    /// Convenience constructor for reloading
    static func reload(metadata: Metadata? = nil, _ values: [Element]) -> IndexedMutation<Element, Metadata> {
        return IndexedMutation<Element, Metadata>(reload: values)
    }
    
    /// Creates a new IndexedMutation by mapping the values array from this transform. NOTE: metdata is passed through unchanged.
    func mapValues<Other>(_ transform: (Element) -> Other) -> IndexedMutation<Other, Metadata> {
        return IndexedMutation<Other, Metadata>(kind: kind, metadata: metadata, indexSet: indexSet, values: values.map(transform))
    }
    
    /// Creates a new IndexedMutation by mapping the values array from this transform. NOTE: metdata is passed through unchanged.
    func mapMetadata<Alternate>(_ transform: (Metadata) -> Alternate) -> IndexedMutation<Element, Alternate> {
        return IndexedMutation<Element, Alternate>(kind: kind, metadata: metadata.map(transform), indexSet: indexSet, values: values)
    }
    
    /// Given a previous row count, returns the new row count after this mutation
    ///
    /// - Parameter rowCount: old number of rows
    func delta(_ rowCount: inout Int) {
        switch kind {
        case .reload: rowCount = values.count
        case .delete: rowCount -= indexSet.count
        case .scroll(let offset): rowCount += values.count - (offset > 0 ? offset : -offset)
        case .insert: rowCount += values.count
        case .move: return
        case .update: return
        }
    }
    
    /// A no-op on rows is explicitly defined as an `.update` with an empty `values` array. Note that metadata may still be non-nil.
    var hasNoEffectOnValues: Bool {
        if case .update = kind, values.count == 0 {
            return true
        }
        return false
    }
    
    func insertionsAndRemovals(length: Int, insert: (Int, Element) -> Void, remove: (Int) -> Void) {
        switch kind {
        case .delete:
            indexSet.reversed().forEach { remove($0) }
        case .scroll(let offset):
            if offset > 0 {
                (0..<offset).forEach { remove($0) }
                values.enumerated().forEach { insert(length - offset + $0.offset, $0.element) }
            } else {
                ((length + offset)..<length).forEach { remove($0) }
                values.enumerated().forEach { insert($0.offset, $0.element) }
            }
        case .move(let index):
            indexSet.forEach { remove($0) }
            values.enumerated().forEach { insert(index + $0.offset, $0.element) }
        case .insert:
            for (i, v) in zip(indexSet, values) {
                insert(i, v)
            }
        case .update:
            indexSet.forEach { remove($0) }
            for (i, v) in zip(indexSet, values) {
                insert(i, v)
            }
        case .reload:
            (0..<length).reversed().forEach { remove($0) }
            values.enumerated().forEach { insert($0.offset, $0.element) }
        }
    }
}

public typealias ArrayMutation<Element> = IndexedMutation<Element, Void>

extension IndexedMutation where Metadata == Void {
    /// Apply the mutation described by this value to the provided array
    func apply<C: RangeReplaceableCollection & MutableCollection>(to a: inout C) where C.Index == Int, C.Iterator.Element == Element {
        switch kind {
        case .delete:
            indexSet.rangeView.reversed().forEach { a.removeSubrange($0) }
        case .scroll(let offset):
            a.removeSubrange(offset > 0 ? a.startIndex..<offset : (a.endIndex + offset)..<a.endIndex)
            a.insert(contentsOf: values, at: offset > 0 ? a.endIndex : a.startIndex)
        case .move(let index):
            let moving = indexSet.map { a[$0] }
            indexSet.rangeView.reversed().forEach { a.removeSubrange($0) }
            a.insert(contentsOf: moving, at: index)
        case .insert:
            for (i, v) in zip(indexSet, values) {
                a.insert(v, at: i)
            }
        case .update:
            var progress = 0
            indexSet.rangeView.forEach { r in
                a.replaceSubrange(r, with: values[progress..<(progress + r.count)])
                progress += r.count
            }
        case .reload:
            a.replaceSubrange(a.startIndex..<a.endIndex, with: values)
        }
    }
}

public enum SetMutationKind {
    case delete
    case insert
    case update
    case reload
}

public struct SetMutation<Element> {
    public let kind: SetMutationKind
    public let values: Array<Element>
    
    public init(kind: SetMutationKind, values: Array<Element>) {
        self.kind = kind
        self.values = values
    }
    
    public static func delete(_ values: Array<Element>) -> SetMutation<Element> {
        return SetMutation(kind: .delete, values: values)
    }
    
    public static func insert(_ values: Array<Element>) -> SetMutation<Element> {
        return SetMutation(kind: .insert, values: values)
    }
    
    public static func update(_ values: Array<Element>) -> SetMutation<Element> {
        return SetMutation(kind: .update, values: values)
    }
    
    public static func reload(_ values: Array<Element>) -> SetMutation<Element> {
        return SetMutation(kind: .reload, values: values)
    }
    
    public func apply(to array: inout Array<Element>, equate: @escaping (Element, Element) -> Bool, compare: @escaping (Element, Element) -> Bool) -> [ArrayMutation<Element>] {
        switch kind {
        case .delete:
            var sorted = values.sorted(by: compare)
            var oldIndices = IndexSet()
            var arrayIndex = 0
            var sortedIndex = 0
            while arrayIndex < array.count && sortedIndex < sorted.count {
                if !equate(array[arrayIndex], sorted[sortedIndex]) {
                    arrayIndex += 1
                } else {
                    oldIndices.insert(arrayIndex)
                    sortedIndex += 1
                    arrayIndex += 1
                }
            }
            precondition(sortedIndex == sorted.count, "Unable to find deleted items.")
            oldIndices.reversed().forEach { array.remove(at: $0) }
            return [ArrayMutation<Element>(deletedIndexSet: oldIndices)]
        case .insert:
            var sorted = values.sorted(by: compare)
            var newIndices = IndexSet()
            var arrayIndex = 0
            var sortedIndex = 0
            while arrayIndex < array.count && sortedIndex < sorted.count {
                if compare(array[arrayIndex], sorted[sortedIndex]) {
                    arrayIndex += 1
                } else {
                    newIndices.insert(arrayIndex)
                    array.insert(sorted[sortedIndex], at: arrayIndex)
                    sortedIndex += 1
                    arrayIndex += 1
                }
            }
            while sortedIndex < sorted.count {
                newIndices.insert(arrayIndex)
                array.insert(sorted[sortedIndex], at: arrayIndex)
                sortedIndex += 1
                arrayIndex += 1
            }
            return [ArrayMutation<Element>(insertedIndexSet: newIndices, values: sorted)]
        case .update:
            // It would be nice if this was better than n squared complexity and aggregated the updates, rather than issueing updates for individual rows.
            var result = Array<ArrayMutation<Element>>()
            for v in values {
                let oldIndex = array.firstIndex { u in equate(v, u) }!
                array.remove(at: oldIndex)
                let newIndex = array.firstIndex { u in compare(v, u) } ?? array.count
                array.insert(v, at: newIndex)
                if newIndex == oldIndex {
                    result.append(.updated(v, at: oldIndex))
                } else {
                    // This ordering (moved, then updated) is required to make UITableView animations work correctly.
                    result.append(.moved(from: oldIndex, to: newIndex))
                    result.append(.updated(v, at: newIndex))
                }
            }
            return result
        case .reload:
            array = values.sorted(by: compare)
            return [ArrayMutation<Element>(reload: array)]
        }
    }
}

extension SignalInterface {
    public func sortedArrayMutation<Element>(equate: @escaping (Element, Element) -> Bool, compare: @escaping (Element, Element) -> Bool) -> Signal<ArrayMutation<Element>> where SetMutation<Element> == OutputValue {
        return transform(initialState: Array<Element>()) { (array: inout Array<Element>, result: Signal<SetMutation<Element>>.Result) in
            switch result {
            case .success(let m): return .values(sequence: m.apply(to: &array, equate: equate, compare: compare))
            case .failure(let e): return .end(e)
            }
        }
    }
}


public enum StackMutation<Value>: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        self = .reload(elements)
    }
    
    public typealias ArrayLiteralElement = Value
    
    case push(Value)
    case pop
    case popToCount(Int)
    case reload([Value])
    
    func apply(to stack: inout Array<Value>) {
        switch self {
        case .push(let v): stack.append(v)
        case .pop: stack.removeLast()
        case .popToCount(let c): stack.removeLast(stack.count - c)
        case .reload(let newStack): stack = newStack
        }
    }
}

extension SignalInterface {
    public func stackMap<A, B>(_ transform: @escaping (A) -> B) -> Signal<StackMutation<B>> where OutputValue == StackMutation<A> {
        return map { m in
            switch m {
            case .push(let a): return StackMutation<B>.push(transform(a))
            case .pop: return StackMutation<B>.pop
            case .popToCount(let i): return StackMutation<B>.popToCount(i)
            case .reload(let array): return StackMutation<B>.reload(array.map { transform($0) })
            }
        }
    }
}

/// When used as the `Metadata` parameter to an `IndexedMutation`, then the indexed mutation can represent a locally visible subrange within a larger global array.
/// NOTE: when `nil` the following behaviors are implied for each IndexedMutation kind:
///    - reload: the localOffset is 0 and the globalCount is the reload count
///   - delete: the globalCount is reduced by the deletion count 
///   - insert: the globalCount is increased by the insertion count 
///   - scroll: the localOffset is changed by the scroll count
///   - update: neither localOffset nor globalCount are changed
///   - move: neither localOffset nor globalCount are changed
public struct Subrange<Leaf> {
    /// This is offset for the visible range. When not provided, the `localOffset` is automatically updated by `.scroll` and reset to `0` on `.reload`.
    /// NOTE: `localOffset` doesn't affect the `IndexedMutation` itself (since the mutation operates entirely in local coordinates) but for animation purposes (which typically needs to occur in global coordinates), the `localOffset` is considered to apply *before* the animation (e.g. the scroll position shifts first, then the values in the new locations are updated).
    public let localOffset: Int?
    
    /// This is the length of the greater array after the mutation is applied. When not provided, the `globalCount` is automatically updated by `.insert`, `.delete` and reset to the local count on `.reload`.
    public let globalCount: Int?
    
    /// Additional metadata for this tier
    public let leaf: Leaf?
    
    public init(localOffset: Int?, globalCount: Int?, leaf: Leaf?) {
        self.localOffset = localOffset
        self.globalCount = globalCount
        self.leaf = leaf
    }
}

/// A data type that can be used to cache the destination end of a `Subrange<Leaf>` change stream.
public struct SubrangeState<Element, Leaf> {
    public var values: Deque<Element>?
    public var localOffset: Int = 0
    public var globalCount: Int = 0
    public var leaf: Leaf?
    
    public init(values: Deque<Element>? = nil, localOffset: Int = 0, globalCount: Int? = nil, leaf: Leaf? = nil) {
        self.values = values
        self.localOffset = localOffset
        self.globalCount = globalCount ?? values?.count ?? 0
        self.leaf = leaf
    }
}

public typealias SubrangeMutation<Element, Additional> = IndexedMutation<Element, Subrange<Additional>>

extension IndexedMutation {
    public func updateMetadata<Value, Leaf>(_ state: inout SubrangeState<Value, Leaf>) where Subrange<Leaf> == Metadata {
        switch kind {
        case .reload:
            state.localOffset = metadata?.localOffset ?? 0
            state.globalCount = metadata?.globalCount ?? values.count
            state.leaf = metadata?.leaf ?? nil
        case .delete:
            if let localOffset = metadata?.localOffset {
                state.localOffset = localOffset
            }
            state.globalCount = metadata?.globalCount ?? (state.globalCount - indexSet.count)
            if let leaf = metadata?.leaf {
                state.leaf = leaf
            }
        case .insert:
            if let localOffset = metadata?.localOffset {
                state.localOffset = localOffset
            }
            state.globalCount = metadata?.globalCount ?? (state.globalCount + indexSet.count)
            if let leaf = metadata?.leaf {
                state.leaf = leaf
            }
        case .scroll(let offset):
            state.localOffset = metadata?.localOffset ?? (state.localOffset + offset)
            if let globalCount = metadata?.globalCount {
                state.globalCount = globalCount
            }
            if let leaf = metadata?.leaf {
                state.leaf = leaf
            }
        case .update: fallthrough
        case .move:
            if let localOffset = metadata?.localOffset {
                state.localOffset = localOffset
            }
            if let globalCount = metadata?.globalCount {
                state.globalCount = globalCount
            }
            if let leaf = metadata?.leaf {
                state.leaf = leaf
            }
        }
    }
    
    public func apply<Submetadata>(toSubrange state: inout SubrangeState<Element, Submetadata>) where Subrange<Submetadata> == Metadata {
        if !hasNoEffectOnValues {
            var rows = state.values ?? []
            mapMetadata { _ in () }.apply(to: &rows)
            state.values = rows
        }
        
        updateMetadata(&state)
    }
}

extension IndexSet {
    /// Maintaining an `SubrangeOffset` with a local offset may require offsetting an `IndexSet`
    public func offset(by: Int) -> IndexSet {
        if by == 0 {
            return self
        }
        var result = IndexSet()
        for range in self.rangeView {
            result.insert(integersIn: (range.startIndex + by)..<(range.endIndex + by))
        }
        return result
    }
}

public struct TreeMutation<Leaf>: ExpressibleByArrayLiteral {
    public let mutations: IndexedMutation<TreeMutation<Leaf>, Leaf>
    
    public init(mutations: IndexedMutation<TreeMutation<Leaf>, Leaf>) {
        self.mutations = mutations
    }
    
    public init(arrayLiteral elements: TreeMutation<Leaf>...) {
        self.mutations = .reload(elements)
    }
    
    public static func leaf(_ value: Leaf, children: [TreeMutation<Leaf>]? = nil) -> TreeMutation<Leaf> {
        return TreeMutation<Leaf>(mutations: children.map { IndexedMutation(metadata: value, reload: $0) } ?? IndexedMutation(metadata: value))
    }
    
    public static func leaf<Value>(_ value: Value, children: [TreeMutation<Leaf>]? = nil) -> TreeMutation<Leaf> where Subrange<Value> == Leaf {
        let subrange = Subrange(localOffset: children.map { _ in 0 }, globalCount: children.map { $0.count }, leaf: value)
        return TreeMutation<Leaf>(mutations: children.map { IndexedMutation(metadata: subrange, reload: $0) } ?? IndexedMutation(metadata: subrange))
    }
}

public class TreeState<Metadata> {
    public weak var parent: TreeState<Metadata>?
    public var metadata: Metadata? = nil
    public var rows: Array<TreeState<Metadata>>? = nil
    
    public init(parent: TreeState<Metadata>?) {}
    
    public convenience init(parent: TreeState<Metadata>?, treeMutation: TreeMutation<Metadata>) {
        self.init(parent: parent)
        treeMutation.mutations.apply(toTree: self)
    }
}

public typealias TreeSubrangeMutation<Leaf> = TreeMutation<Subrange<Leaf>>

extension IndexedMutation where Element == TreeMutation<Metadata> {
    public func apply(toTree treeState: TreeState<Metadata>) {
        if let metadata = metadata {
            treeState.metadata = metadata
        }
        
        if !hasNoEffectOnValues {
            var rows: Array<TreeState<Metadata>> = []
            if case .update = kind {
                for (mutationIndex, rowIndex) in indexSet.enumerated() {
                    values[mutationIndex].mutations.apply(toTree: rows[rowIndex])
                }
            } else {
                mapValues { mutation in TreeState<Metadata>.init(parent: treeState, treeMutation: mutation) }.mapMetadata { _ in () }.apply(to: &rows)
            }
            treeState.rows = rows
        }
    }
}

public typealias TreeRangeMutation<Leaf> = TreeMutation<Subrange<Leaf>>

public class TreeSubrangeState<Leaf> {
    public weak var parent: TreeSubrangeState<Leaf>?
    public var state = SubrangeState<TreeSubrangeState<Leaf>, Leaf>()
    
    public init(parent: TreeSubrangeState<Leaf>?) {}
    
    public convenience init(parent: TreeSubrangeState<Leaf>?, treeSubrangeMutation: TreeSubrangeMutation<Leaf>) {
        self.init(parent: parent)
        treeSubrangeMutation.mutations.apply(toTreeSubrange: self)
    }
}

extension IndexedMutation where Element == TreeMutation<Metadata> {
    public func apply<Leaf>(toTreeSubrange treeSubrangeState: TreeSubrangeState<Leaf>) where Subrange<Leaf> == Metadata {
        if !hasNoEffectOnValues {
            if case .update = kind {
                for (mutationIndex, rowIndex) in indexSet.enumerated() {
                    values[mutationIndex].mutations.apply(toTreeSubrange: treeSubrangeState.state.values![rowIndex])
                }
            } else {
                mapValues { mutation in TreeSubrangeState<Leaf>.init(parent: treeSubrangeState, treeSubrangeMutation: mutation) }.apply(toSubrange: &treeSubrangeState.state)
            }
        }
        updateMetadata(&treeSubrangeState.state)
    }
}
