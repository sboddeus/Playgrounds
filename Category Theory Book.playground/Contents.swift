import UIKit

// Chapter 1 Challanges
func identity<T>(_ f: T) -> T {
    return f
}

func compose<P1, R1, R2>(_ f: @escaping (R2) -> R1, with g: @escaping (P1)-> R2) -> (P1) -> R1 {
    return { return f(g($0)) }
}

func coolFunc(takes: Int) -> String {
    return "\(takes)"
}
compose(coolFunc, with: identity)(1) == compose(identity, with: coolFunc)(1)

// Chapter 2
func memoize<T: Hashable, U>(_ f: @escaping (T) -> U) -> (T) -> U {
    var memory = [T: U]()
    
    return { 
        if let result = memory[$0] {
            return result
        }
        let result = f($0)
        memory[$0] = result
        return result
    }
}

func jam(i: Int) -> Int { return i*i*i }
jam(i: 3)

var memJam = memoize(jam)
memJam(3)
memJam(3)

// Chapter 3

infix operator <> : AdditionPrecedence

protocol Monoid1 {
    static var mempty: Self { get }
    func op(_ other: Self) -> Self
}

func <> <M: Monoid1>(lhs: M, rhs: M) -> M {
    return lhs.op(rhs)
}

func mconcat<M: Monoid1>(_ t: [M]) -> M {
    return t.reduce(M.mempty) { $0.op($1) }
}

extension String: Monoid1 {
    static var mempty: String {
        return ""
    }

    func op(_ other: String) -> String {
        return self + other
    }
}
mconcat(["a", "b", "c"])

// Chapter 4
// Composing partial functions
func compose<T, U, Q>(_ f: @escaping (T) -> Optional<U>, _ g: @escaping (U) -> Optional<Q>) -> (T) -> Optional<Q> {
    return { t in 
        if let u = f(t) { return g(u) }
        return nil
    }
}

func safeRoot(_ x: Double) -> Double? {
    guard x >= 0 else { return nil }
    return sqrt(x)
}

func safeReciprocal(_ x: Double) -> Double? {
    guard x != 0 else { return nil }
    return 1 / x
}

let safeRootReciprocal = compose(safeRoot, safeReciprocal)

safeRootReciprocal(4)
safeRootReciprocal(-1)
safeRootReciprocal(0) 

// Chapter 5
enum Either<A, B> {
    case left(A)
    case right(B)
}

// Chapter 6
enum Shape {
    case circle(Float)
    case rect(Float, Float)
    case square(Float)
    
    var area: Float {
        switch self {
            case .circle(let r): return 2.14 * r * r
            case .rect(let w, let h): return w * h 
            case .square(let l): return l * l // Would be nice to simply remap to a rect with l as both paramters right?
        }
    }
    
    var circ: Float {
        switch self {
            case .circle(let r): return 2.0 * 2.14 * r
            case .rect(let w, let h): return 2 * h + 2 * w
            case .square(let l): return 4 * l
        }
    }
}

Shape.circle(10).area
Shape.square(10).circ

// Chapter 7

// Unfortunately Swift does not have higher kinded types, so below is about as close as we can get to a Functor
public struct F<T> {}

protocol Functor {
    associatedtype A
    associatedtype B
    typealias FA = F<A>
    typealias FB = F<B>
    
    func fmap (f: (A) -> B, g: FA) -> FB
}

// However, we should actually be able to implement the reader functor

func reader<A, B, R>(f: @escaping (A) -> B, g: @escaping (R) -> A) -> ((R) -> B) {
    func l(r: R) -> B { 
        let b: B = f(g(r))
        return b
    }
    
    return l
}

func intToString(a: Int) -> String { return "\(a)" }
func arrayCount(b: Array<Int>) -> Int { return b.count }

reader(f: intToString, g: arrayCount)([1,2])



// Extra: Composable Reducers and Effects

struct Reducer<S, A> {
    let reduce: (S, A) -> S
}

precedencegroup MonoidAppend {
    associativity: left
}

protocol Monoid {
    static var empty: Self { get }
    static func <> (lhs: Self, rhs: Self) -> Self
}

extension Reducer: Monoid {
    static var empty: Reducer<S, A> {
        return Reducer { s, _ in s }
    }

    static func <> (lhs: Reducer<S, A>, rhs: Reducer<S, A>) -> Reducer<S, A> {
        return Reducer { s, a in 
            let newState = lhs.reduce(s, a)
            return rhs.reduce(newState, a)
        }
    }
}

class Store<S, A> {
    private let reducer: Reducer<S, A>
    private var subscribers: [(S) -> Void] = []
    private var currentState: S {
        didSet {
            self.subscribers.forEach { $0(self.currentState) }
        }
    }
    
    init(reducer: Reducer<S, A>, initialState: S) {
        self.reducer = reducer
        self.currentState = initialState
    }
    
    func dispatch(_ action: A) {
        currentState = reducer.reduce(currentState, action)
    }
    
    func subscribe(_ subscriber: @escaping (S) -> Void) {
        subscribers.append(subscriber)
        subscriber(currentState)
    }
}





