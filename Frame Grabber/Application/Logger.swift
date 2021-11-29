import os.log
import Foundation

extension Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "de.arthurhammer.FrameGrabber"

    static let app: Logger? = Logger(subsystem: subsystem, category: "app")
}
