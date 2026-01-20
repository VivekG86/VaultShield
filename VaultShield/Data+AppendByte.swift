import Foundation

extension Data {
    mutating func append(_ byte: UInt8) {
        self.append(contentsOf: [byte])
    }
}
