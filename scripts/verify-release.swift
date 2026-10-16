import Foundation
import CryptoKit

// Verify using only the public key embedded in the shipped app, never a secret.
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let config = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "release/config.json"))) as! [String: String]
let key = try Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: config["sparklePublicKey"]!)!)
let feed = try Data(contentsOf: directory.appendingPathComponent("appcast.xml"))
let marker = Data("<!-- sparkle-signatures:\n".utf8)
guard let range = feed.range(of: marker, options: .backwards) else { fatalError("Missing signed feed trailer") }
let trailer = String(decoding: feed[range.upperBound...], as: UTF8.self)
let fields = Dictionary(uniqueKeysWithValues: trailer.split(separator: "\n").compactMap { line -> (String, String)? in
    let pair = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
    return pair.count == 2 ? (pair[0], pair[1]) : nil
})
guard Int(fields["length"] ?? "") == range.lowerBound,
      let signature = Data(base64Encoded: fields["edSignature"] ?? ""),
      key.isValidSignature(signature, for: feed.prefix(range.lowerBound)) else { fatalError("Feed signature invalid") }
final class Enclosure: NSObject, XMLParserDelegate {
    var attributes: [String: String] = [:]
    func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        if element == "enclosure" { self.attributes = attributes }
    }
}
let enclosure = Enclosure()
let parser = XMLParser(data: feed)
parser.delegate = enclosure
guard parser.parse(), let encoded = enclosure.attributes["sparkle:edSignature"], let archiveSignature = Data(base64Encoded: encoded) else { fatalError("Invalid appcast enclosure") }
let name = "WisprFlowIsDead-\(config["version"]!).zip"
guard enclosure.attributes["url"] == "https://github.com/tommy-muckstack/wisprflowisdead/releases/download/v\(config["version"]!)/\(name)" else { fatalError("Unexpected update URL") }
let archive = try Data(contentsOf: directory.appendingPathComponent(name))
guard Int(enclosure.attributes["length"] ?? "") == archive.count,
      key.isValidSignature(archiveSignature, for: archive) else { fatalError("Update archive signature invalid") }
print("Public-key verification passed: signed feed and update archive")
