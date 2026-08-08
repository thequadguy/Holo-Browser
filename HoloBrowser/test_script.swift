import Foundation
import Combine

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["swift", "build"]
// wait this won't work easily to import modules
