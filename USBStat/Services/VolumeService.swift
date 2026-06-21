//Arif Rakhmanov 6/21/26


import DiskArbitration
import AppKit
import Foundation


class VolumeService {
    
    private let session = DASessionCreate(kCFAllocatorDefault)!
        
    init() {
        DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    func fetchVolumes(for locationID: Int) throws -> [USBVolume] {
        
        var volumes: [USBVolume] = []
        let locationHex = String(format: "%08x", locationID).uppercased()
        
        let volumeURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey],
            options: .skipHiddenVolumes
        )
        
        guard let volumeURLs = volumeURLs else { return [] }
        
        for url in volumeURLs {
            
            guard url.path() != "/" else { continue } // Only USB devices
            
            let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL)
            guard let disk = disk,
                  let desc = DADiskCopyDescription(disk) as? [String: Any] else { continue }
            
            // Filter 2: Only our device
            let busPath = desc["DABusPath"] as? String ?? ""
            guard busPath.uppercased().contains(locationHex) else { continue }
            let protocol_ = desc["DADeviceProtocol"] as? String
            
            guard protocol_ == "USB" else { continue }
            guard busPath.uppercased().contains(locationHex) else { continue }
            
            let values = try url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])
            
            let name       = values.volumeName ?? "Unknown"
            let total      = values.volumeTotalCapacity ?? 0
            let available  = values.volumeAvailableCapacity ?? 0
            
            let volume = USBVolume(
                name: name,
                mountPath: url.path,
                totalBytes: Int64(total),
                usedBytes: Int64(total - available),
                isMounted: true
            )
            
            volumes.append(volume)
        }
        
        return volumes
    }
    
    func fetchUnmountedVolumes(for locationID: Int) -> [USBVolume] {
        var volumes: [USBVolume] = []
        let locationHex = String(format: "%08x", locationID).uppercased()
        
        var iterator: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOMedia"), &iterator)
        
        var mediaService = IOIteratorNext(iterator)
        while mediaService != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(mediaService, &properties, kCFAllocatorDefault, 0)
            
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                let bsdName = dict["BSD Name"] as? String ?? ""
                
                if !bsdName.isEmpty {
                    let disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, bsdName)
                    if let disk = disk,
                       let desc = DADiskCopyDescription(disk) as? [String: Any] {
                        
                        let busPath = desc["DABusPath"] as? String ?? ""
                        let protocol_ = desc["DADeviceProtocol"] as? String
                        let isMounted = desc["DAVolumePath"] != nil
                        let isLeaf = desc["DAMediaLeaf"] as? Bool ?? false
                        
                        if isLeaf && protocol_ == "USB" && busPath.uppercased().contains(locationHex) && !isMounted {
                            let volume = USBVolume(
                                name: bsdName,
                                mountPath: "",
                                totalBytes: 0,
                                usedBytes: 0,
                                isMounted: false
                            )
                            volumes.append(volume)
                        }
                    }
                }
            }
            
            IOObjectRelease(mediaService)
            mediaService = IOIteratorNext(iterator)
        }
        
        IOObjectRelease(iterator)
        return volumes
    }
    
    func eject(_ volume: USBVolume, completion: @escaping (Bool) -> Void) throws {
        guard let url = URL(string: "file://\(volume.mountPath)") else {
            completion(false)
            return
        }
        
        try NSWorkspace.shared.unmountAndEjectDevice(at: url)
           completion(true)
        NotificationService.shared.sendNotification(title: "Ejected successfuly", body: volume.mountPath)
    }
}
