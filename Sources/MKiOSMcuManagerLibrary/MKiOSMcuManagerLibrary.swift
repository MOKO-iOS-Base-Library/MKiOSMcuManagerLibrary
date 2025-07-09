import Foundation
import CoreBluetooth
import iOSMcuManagerLibrary

@objc public class MKiOSDFUManager: NSObject {
    private var dfuManager: FirmwareUpgradeManager?
    private var progressHandler: ((CGFloat) -> Void)?
    private var successHandler: (() -> Void)?
    private var failureHandler: ((NSError) -> Void)?
    
    enum MKiOSDFUError: Error {
            case cancel
            case connectionFailed
            case invalidHallSensorData
            case invalidResetButtonData
            case invalidSensorData
            
            var errorDescription: String? {
                switch self {
                case .cancel:
                    return "Upgrade has been canceled."
                case .connectionFailed:
                    return "Connect Failed"
                case .invalidHallSensorData:
                    return "Hall Sensor Error"
                case .invalidResetButtonData:
                    return "Reset By Button Error"
                case .invalidSensorData:
                    return "Sensor Type Error"
                }
            }
    }
    
    @objc public init(peripheral: CBPeripheral) {
        super.init()
        let transporter = McuMgrBleTransport(peripheral)
        dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self)
    }
    
    @objc public func updateWithFileUrl(_ url: String,
                                progressBlock: @escaping (CGFloat) -> Void,
                                sucBlock: @escaping () -> Void,
                                failedBlock: @escaping (NSError) -> Void) {
        // 存储回调
        self.progressHandler = progressBlock
        self.successHandler = sucBlock
        self.failureHandler = failedBlock
        
        guard let fileUrl = URL(string: url) else {
            failedBlock(NSError(domain: "MKiOSDFUManager", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "无效文件URL"]))
            return
        }
        
        do {
            // 使用正确的类型 McuMgrPackage
            let package = try Data(contentsOf: fileUrl)
            try dfuManager?.start(data: package)  // 正确调用start方法
        } catch {
            failedBlock(error as NSError)
        }
    }
}

// MARK: - FirmwareUpgradeDelegate
extension MKiOSDFUManager: FirmwareUpgradeDelegate {
    public func upgradeDidComplete() {
        successHandler?()
    }
    
    public func upgradeDidFail(inState state: iOSMcuManagerLibrary.FirmwareUpgradeState, with error: any Error) {
        failureHandler?(error as NSError)
    }
    
    public func upgradeDidCancel(state: iOSMcuManagerLibrary.FirmwareUpgradeState) {
        failureHandler?(MKiOSDFUError.cancel as NSError)
    }
    
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        let progress = CGFloat(bytesSent) / CGFloat(imageSize)
        self.progressHandler?(progress)
    }
    
    public func upgradeDidStart(controller: FirmwareUpgradeController) {
        print("DFU开始")
    }
    
    public func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        
    }
}
