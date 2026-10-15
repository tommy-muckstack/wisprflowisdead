import Foundation

/// 16-bit PCM mono WAV, enough to keep a take for Retry, Recover and playback.
public enum WAV {
    public static func encode(_ samples: [Float], sampleRate: Int = 16_000) -> Data {
        var data = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let byteCount = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); u32(36 + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate * 2)); u16(2); u16(16)
        data.append(contentsOf: Array("data".utf8)); u32(byteCount)
        data.reserveCapacity(data.count + samples.count * 2)
        for s in samples {
            let clamped = max(-1, min(1, s))
            u16(UInt16(bitPattern: Int16(clamped * Float(Int16.max))))
        }
        return data
    }

    /// Decodes what `encode` writes (16-bit PCM mono). Returns nil otherwise.
    public static func decode(_ data: Data) -> (samples: [Float], sampleRate: Int)? {
        let bytes = [UInt8](data)
        guard bytes.count >= 44, String(bytes: bytes[0..<4], encoding: .ascii) == "RIFF",
              String(bytes: bytes[8..<12], encoding: .ascii) == "WAVE" else { return nil }
        func u32(_ o: Int) -> Int { Int(bytes[o]) | Int(bytes[o+1]) << 8 | Int(bytes[o+2]) << 16 | Int(bytes[o+3]) << 24 }
        func u16(_ o: Int) -> Int { Int(bytes[o]) | Int(bytes[o+1]) << 8 }
        var offset = 12
        var rate = 16_000
        var bits = 16
        var channels = 1
        while offset + 8 <= bytes.count {
            let id = String(bytes: bytes[offset..<offset+4], encoding: .ascii) ?? ""
            let size = u32(offset + 4)
            let body = offset + 8
            if id == "fmt " {
                channels = u16(body + 2); rate = u32(body + 4); bits = u16(body + 14)
            } else if id == "data" {
                guard bits == 16, channels == 1 else { return nil }
                let end = min(bytes.count, body + size)
                var out: [Float] = []
                out.reserveCapacity((end - body) / 2)
                var i = body
                while i + 1 < end {
                    let v = Int16(bitPattern: UInt16(bytes[i]) | UInt16(bytes[i+1]) << 8)
                    out.append(Float(v) / Float(Int16.max))
                    i += 2
                }
                return (out, rate)
            }
            offset = body + size + (size % 2)
        }
        return nil
    }
}
