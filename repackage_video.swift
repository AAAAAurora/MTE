import AVFoundation
import Foundation

enum RepackageError: Error {
    case exportSessionUnavailable
    case exportFailed(String)
}

let fileManager = FileManager.default
let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let inputURL = cwd.appendingPathComponent("视频.mp4")
let outputURL = cwd.appendingPathComponent("视频.faststart.mp4")

if fileManager.fileExists(atPath: outputURL.path) {
    try fileManager.removeItem(at: outputURL)
}

let asset = AVURLAsset(url: inputURL)

guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
    throw RepackageError.exportSessionUnavailable
}

exportSession.outputURL = outputURL
exportSession.outputFileType = .mp4
exportSession.shouldOptimizeForNetworkUse = true

let semaphore = DispatchSemaphore(value: 0)
exportSession.exportAsynchronously {
    semaphore.signal()
}
semaphore.wait()

switch exportSession.status {
case .completed:
    let backupURL = cwd.appendingPathComponent("视频.original.mp4")
    if fileManager.fileExists(atPath: backupURL.path) {
        try fileManager.removeItem(at: backupURL)
    }
    try fileManager.moveItem(at: inputURL, to: backupURL)
    try fileManager.moveItem(at: outputURL, to: inputURL)
    print("Repackaged successfully.")
    print("Backup saved as 视频.original.mp4")
case .failed:
    throw RepackageError.exportFailed(exportSession.error?.localizedDescription ?? "unknown error")
case .cancelled:
    throw RepackageError.exportFailed("cancelled")
default:
    throw RepackageError.exportFailed("unexpected status: \(exportSession.status.rawValue)")
}
