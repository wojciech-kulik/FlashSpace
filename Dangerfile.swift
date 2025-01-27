import Danger
import Foundation

let danger = Danger()

// -------- SwiftLint

SwiftLint.lint(
    .modifiedAndCreatedFiles(directory: "FlashSpace"),
    configFile: ".swiftlint.yml"
)

// -------- SwiftFormat

struct SwiftFormatEntry: Decodable {
    let file: String
    let line: Int
    let reason: String
    let ruleId: String
}

_ = ShellExecutor.execute(
    "swiftformat --lint --config .swiftformat --reporter json --report swiftformat-result.json FlashSpace"
)

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let swiftFormatJson = readFile("swiftformat-result.json").data(using: .utf8)!
let swiftFormatResults = try! decoder.decode([SwiftFormatEntry].self, from: swiftFormatJson)

if swiftFormatResults.isEmpty {
    message("The code is correctly formatted")
} else {
    var swiftFormatMarkdown = ""
    swiftFormatMarkdown = "### SwiftFormat report\n"
    swiftFormatMarkdown += "| Rule | File | Reason |\n"
    swiftFormatMarkdown += "|:----------:|-------------|------|\n"
    swiftFormatMarkdown += swiftFormatResults
        .map { "| \($0.ruleId) | \(URL(filePath: $0.file).lastPathComponent):\($0.line) | \($0.reason) |" }
        .joined(separator: "\n")

    markdown(swiftFormatMarkdown)
    fail("Please use SwiftFormat to fix code formatting.")
}

// ------- UTILS

enum ShellExecutor {
    static func execute(_ script: String) -> String {
        let env = ProcessInfo.processInfo.environment
        let task = Process()
        let pipe = Pipe()

        task.launchPath = env["SHELL"]
        task.arguments = ["-l", "-c", script]
        task.currentDirectoryPath = FileManager.default.currentDirectoryPath

        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        return String(data: data, encoding: String.Encoding.utf8)!
    }
}

func readFile(_ file: String) -> String {
    guard let data = FileManager.default.contents(atPath: file) else {
        print("Could not get the contents of '\(file)', failing the Dangerfile evaluation.")
        exit(1)
    }

    guard let string = String(data: data, encoding: .utf8) else {
        print("The '\(file)' could not be converted into a string, is it a binary?.")
        exit(1)
    }

    return string
}
