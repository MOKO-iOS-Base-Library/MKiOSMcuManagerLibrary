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
        
        guard let fileURL = URL(string: url) else {
            failure(NSError(domain: "FirmwareUpdateWrapper",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"]))
            return
        }
        
        self.progressHandler = progress
        self.successHandler = success
        self.failureHandler = failure
        
        do {
            let package = try McuMgrPackage(from: fileURL)
            let configuration = FirmwareUpgradeConfiguration(
                estimatedSwapTime: 10.0,
                eraseAppSettings: false,
                pipelineDepth: 2,
                byteAlignment: .disabled,
                reassemblyBufferSize: 1024,
                upgradeMode: .testAndConfirm
            )
            
            try? dfuManager?.start(package: package, using: configuration)
        } catch {
            failure(error)
        }
    }
    
    @objc public func cancelUpdate() {
        dfuManager?.cancel()
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
        // 升级开始
        print("Start upgrade")
    }
    
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        // 状态变化
        print("Current upgrade state:",newState)
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
                          code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Update cancelled by user"])
        DispatchQueue.main.async {
            self.failureHandler?(error)
            self.cleanup()
        }
    }
    
    private func cleanup() {
        progressHandler = nil
        successHandler = nil
        failureHandler = nil
    }
}
