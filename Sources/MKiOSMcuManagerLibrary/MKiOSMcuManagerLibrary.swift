import Foundation
import CoreBluetooth
import iOSMcuManagerLibrary

@objc public class FirmwareUpdateWrapper: NSObject {
    private var dfuManager: FirmwareUpgradeManager?
    private var transport: McuMgrBleTransport?
    
    // 回调属性
    private var progressHandler: ((CGFloat) -> Void)?
    private var successHandler: (() -> Void)?
    private var failureHandler: ((Error) -> Void)?
    
    @objc public init(peripheral: CBPeripheral) {
        super.init()
        self.transport = McuMgrBleTransport(peripheral)
        self.dfuManager = FirmwareUpgradeManager(transport: transport!, delegate: self)
    }
    
    @objc public func update(withFileUrl url: String,
                           progress: @escaping (CGFloat) -> Void,
                           success: @escaping () -> Void,
                           failure: @escaping (Error) -> Void) {
        
        // 确保在主线程执行
        DispatchQueue.main.async {
            do {
                // 1. 验证并转换URL
                let fileURL = try self.validateAndCreateFileURL(url)
                
                // 2. 验证文件存在
                try self.validateFileExistence(at: fileURL)
                
                // 3. 设置回调
                self.progressHandler = progress
                self.successHandler = success
                self.failureHandler = failure
                
                // 4. 开始更新
                try self.startFirmwareUpdate(with: fileURL)
                
            } catch {
                failure(error)
                self.cleanup()
            }
        }
    }
    
    @objc public func cancelUpdate() {
        dfuManager?.cancel()
    }
    
    // MARK: - Private Methods
    
    private func validateAndCreateFileURL(_ urlString: String) throws -> URL {
        // 先尝试直接转换
        if let fileURL = URL(string: urlString), fileURL.isFileURL {
            return fileURL
        }
        
        // 如果不是fileURL，尝试处理沙盒路径
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileName = (urlString as NSString).lastPathComponent
            let fileURL = documentsDir.appendingPathComponent(fileName)
            if fileURL.isFileURL {
                return fileURL
            }
        }
        
        throw NSError(domain: "FirmwareUpdateWrapper",
                      code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Invalid file URL: \(urlString)"])
    }
    
    private func validateFileExistence(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "FirmwareUpdateWrapper",
                          code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "File not found at path: \(url.path)"])
        }
    }
    
    private func startFirmwareUpdate(with fileURL: URL) throws {
        let package = try McuMgrPackage(from: fileURL)
        let configuration = FirmwareUpgradeConfiguration(
            estimatedSwapTime: 10.0,
            eraseAppSettings: false,
            pipelineDepth: 2,
            byteAlignment: .disabled,
            reassemblyBufferSize: 1024,
            upgradeMode: .testAndConfirm
        )
        
        try dfuManager?.start(package: package, using: configuration)
    }
    
    private func cleanup() {
        progressHandler = nil
        successHandler = nil
        failureHandler = nil
    }
}

extension FirmwareUpdateWrapper: FirmwareUpgradeDelegate {
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        let progress = CGFloat(bytesSent) / CGFloat(imageSize)
        DispatchQueue.main.async {
            self.progressHandler?(progress)
        }
    }
    
    public func upgradeDidStart(controller: FirmwareUpgradeController) {
        print("Firmware upgrade started")
    }
    
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        print("Upgrade state changed from \(previousState) to \(newState)")
    }
    
    public func upgradeDidComplete() {
        DispatchQueue.main.async {
            self.successHandler?()
            self.cleanup()
        }
    }
    
    public func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        DispatchQueue.main.async {
            self.failureHandler?(error)
            self.cleanup()
        }
    }
    
    public func upgradeDidCancel(state: FirmwareUpgradeState) {
        let error = NSError(domain: "FirmwareUpdateWrapper",
                          code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Update cancelled by user"])
        DispatchQueue.main.async {
            self.failureHandler?(error)
            self.cleanup()
        }
    }
}
