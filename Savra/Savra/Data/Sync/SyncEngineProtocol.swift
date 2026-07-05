import Foundation

protocol SyncEngineProtocol: Sendable {
    func start() async
    func stop() async
    func retryPending() async
}
