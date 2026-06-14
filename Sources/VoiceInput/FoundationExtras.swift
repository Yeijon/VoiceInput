import Foundation

extension String {
    func removingHTMLEntities() -> String {
        var result = self
        let mappings: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
        ]
        for (entity, value) in mappings {
            result = result.replacingOccurrences(of: entity, with: value)
        }
        return result
    }
}
