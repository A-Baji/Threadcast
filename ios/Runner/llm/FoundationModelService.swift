import Foundation

// TODO: Implement Foundation Models integration
// Requires iOS 18+, and the Foundation Models entitlement must be enabled in Xcode:
//   Signing & Capabilities -> + Capability -> Foundation Models
// See CLAUDE.md -- iOS: Foundation Models Framework

@available(iOS 18.0, *)
class FoundationModelService {
    func isAvailable() -> Bool { return false }  // TODO
    func generateTranscript(prompt: String) async throws -> String { return "" }  // TODO
}