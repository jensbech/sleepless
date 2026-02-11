public enum PmsetParser {
    /// Parse `pmset -g` output to determine if sleep is disabled.
    public static func isSleepDisabled(pmsetOutput: String) -> Bool {
        for line in pmsetOutput.components(separatedBy: "\n") {
            let lower = line.lowercased()
            if lower.contains("sleepdisabled") || lower.contains("disablesleep") {
                return line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
            }
        }
        return false
    }
}
