import Foundation

precedencegroup MonoidAppend {
    associativity: left
}
infix operator <>
protocol Monoid {
    static var empty: Self { get }
    static func <> (lhs: Self, rhs: Self) -> Self
}

struct Reducer<S, A>: Monoid {
    let reduce: (inout S, A) -> Void
    
    static var empty: Reducer {
        return Reducer { s, _ in }
    }
    
    static func <> (lhs: Reducer, rhs: Reducer) -> Reducer {
        return Reducer { state, action in
            lhs.reduce(&state, action)
            rhs.reduce(&state, action)
        }
    }
}

class Store<S, A> {
    private let reducer: Reducer<S, A>
    private var currentState: S {
        didSet {
            self.subscribers.forEach { $0(self.currentState) }
        }
    }
    private var subscribers: [(S) -> Void] = []
    
    init(reducer: Reducer<S, A>, initialState: S) {
        self.reducer = reducer
        self.currentState = initialState
    }
    
    func dispatch(_ action: A) {
        self.reducer.reduce(&self.currentState, action)
    }
    
    func subscribe(_ subscriber: @escaping (S) -> Void) {
        self.subscribers.append(subscriber)
        subscriber(self.currentState)
    }
}

struct User {
    let id: Int
    let name: String
}

struct Episode {
    let id: Int
    let title: String
    let videoUrl: String
}

struct Settings {
    var notificationsOn: Bool = false
}

struct EpisodesState {
    var episodes: [Episode] = []
}

struct AccountState {
    var loggedInUser: User? = nil
    var settings: Settings = .init()
}

enum AppAction {
    case accountAction(AccountAction)
    case episodesAction(EpisodesAction)
}

enum EpisodesAction {
    case tappedEpisode(Episode)
}

struct AppState {
    var episodesState: EpisodesState = .init()
    var accountState: AccountState = .init()
    var watchedEpisodes: [Episode] = []
}

enum AccountAction {
    case login(User)
    case tappedEpisode(Episode)
    case tappedLogout
    case tappedNotification(on: Bool)
}

let accountReducer = Reducer<(AccountState, [Episode]), AccountAction> { state, action in
    var (accountState, watchedEpisodes) = state
    defer { state = (accountState, watchedEpisodes) }
    
    switch action {
    case let .login(user):
        accountState.loggedInUser = user
        
    case let .tappedEpisode(episode):
        watchedEpisodes.append(episode)
        
    case .tappedLogout:
        accountState.loggedInUser = nil
        watchedEpisodes = []
        
    case let .tappedNotification(on):
        accountState.settings.notificationsOn = on
    }
}

let episodeReducer = Reducer<(EpisodesState, [Episode]), EpisodesAction> { state, action in
    var (episodeState, watchedEpisodes) = state
    defer { state = (episodeState, watchedEpisodes) }
    
    switch action {
    case let .tappedEpisode(episode):
        watchedEpisodes.append(episode)
    }
}

extension Reducer {
    func lift<T>(state: WritableKeyPath<T, S>) -> Reducer<T, A> {
        return Reducer<T, A> { stateT, action in
            self.reduce(&stateT[keyPath: state], action)
        }
    }
}

struct Prism<A, B> {
    let preview: (A) -> B?
    let review: (B) -> A
}

extension Reducer {
    func lift<B>(action: Prism<B, A>) -> Reducer<S, B> {
        return Reducer<S, B> { state, actionB in
            guard let actionA = action.preview(actionB) else { return }
            self.reduce(&state, actionA)
        }
    }
}

extension AppAction {
    enum prism {
        static let accountAction = Prism<AppAction, AccountAction>(
            preview: {
                if case let .accountAction(action) = $0 { return action }
                return nil
        },
            review: AppAction.accountAction
        )
        static let episodesAction = Prism<AppAction, EpisodesAction>(
            preview: {
                if case let .episodesAction(action) = $0 { return action }
                return nil
        },
            review: AppAction.episodesAction
        )
    }
}

extension Reducer {
    func lift<T, B>(state: WritableKeyPath<T, S>, action: Prism<B, A>) -> Reducer<T, B> {
        return self.lift(state: state).lift(action: action)
    }
}

struct Lens<A, B> {
    let view: (A) -> B
    let mutatingSet: (inout A, B) -> Void
    
    func set(_ whole: A, _ part: B) -> A {
        var result = whole
        self.mutatingSet(&result, part)
        return result
    }
}

func both<A, B, C>(_ lhs: Lens<A, B>, _ rhs: Lens<A, C>) -> Lens<A, (B, C)> {
    return Lens<A, (B, C)>(
        view: { (lhs.view($0), rhs.view($0)) },
        mutatingSet: { whole, parts in
            lhs.mutatingSet(&whole, parts.0)
            rhs.mutatingSet(&whole, parts.1)
    })
}

func lens<A, B>(_ keyPath: WritableKeyPath<A, B>) -> Lens<A, B> {
    return Lens<A, B>(
        view: { $0[keyPath: keyPath] },
        mutatingSet: { whole, part in
            whole[keyPath: keyPath] = part
    })
}

let episodesAndNotificationsLens: Lens<AppState, ([Episode], Bool)> =
    both(
        lens(\.episodesState.episodes),
        lens(\.accountState.settings.notificationsOn)
)

extension Reducer {
    func lift<T, B>(state: Lens<T, S>, action: Prism<B, A>) -> Reducer<T, B> {
        return Reducer<T, B> { stateT, actionB in
            guard let actionA = action.preview(actionB) else { return }
            var stateS = state.view(stateT)
            self.reduce(&stateS, actionA)
            state.mutatingSet(&stateT, stateS)
        }
    }
}

let appReducer: Reducer<AppState, AppAction> =
    accountReducer
        .lift(state: both(lens(\.accountState), lens(\.watchedEpisodes)),
              action: AppAction.prism.accountAction)
        <>
        episodeReducer
            .lift(state: both(lens(\.episodesState), lens(\.watchedEpisodes)),
                  action: AppAction.prism.episodesAction)

let ep1 = Episode(id: 1, title: "Functions", videoUrl: "ep1.mp4")
let ep2 = Episode(id: 2, title: "Monoids", videoUrl: "ep2.mp4")
let ep3 = Episode(id: 3, title: "Functors", videoUrl: "ep3.mp4")

let store = Store(
    reducer: appReducer,
    initialState: AppState(
        episodesState: EpisodesState(
            episodes: [ep1, ep2, ep3]
        ),
        accountState: AccountState(
            loggedInUser: nil,
            settings: Settings(notificationsOn: false)
        ),
        watchedEpisodes: []
    )
)

store.subscribe {
    dump($0)
    print("-----------")
    print("-----------")
}

let user = User(id: 1, name: "Blob")

store.dispatch(.episodesAction(.tappedEpisode(ep1)))
store.dispatch(.episodesAction(.tappedEpisode(ep3)))
store.dispatch(.accountAction(.login(user)))
store.dispatch(.accountAction(.tappedNotification(on: true)))

/*:
 Now this is starting to look really nice. We can have reducers be hyper specific about what data and actions they take, while still being able to lift them into the global world where they can be easily composed.
 Further, just as we allowed state to be split across multiple fields, it's possible to do the same with enums. After all, structs and enums are duals to each other, and so anything you can do with one there should be some form of that with the other.
 The corresponding notion of `both` in the prism/enum world is `either`. First we need an `Either` enum:
 */

enum Either<A, B> {
    case left(A)
    case right(B)
}

/*:
 Then we can construct an operator for combining two prisms:
 */

func either<A, B, C>(_ lhs: Prism<A, B>, _ rhs: Prism<A, C>) -> Prism<A, Either<B, C>> {
    return Prism<A, Either<B, C>>(
        preview: {
            lhs.preview($0).map(Either.left) ?? rhs.preview($0).map(Either.right)
    },
        review: {
            switch $0 {
            case let .left(b):  return lhs.review(b)
            case let .right(c): return rhs.review(c)
            }
    })
}

/*:
 Now we finally used `review`.
 */

print("✅")

