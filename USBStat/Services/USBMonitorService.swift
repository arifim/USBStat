//Arif Rakhmanov 6/21/26


import IOKit
import IOKit.usb
import Foundation
import DiskArbitration
import UserNotifications


class USBMonitorService {
    
    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    
    private var daSession: DASession?
    
    private var volumeService = VolumeService()
    
    // Callback — вызывается когда что-то изменилось
    var onDevicesChanged: (([USBDevice]) -> Void)?
    
    private func startVolumeMonitoring() {
        daSession = DASessionCreate(kCFAllocatorDefault)
        guard let session = daSession else { return }
        
        // Добавляем сессию в RunLoop
        DASessionScheduleWithRunLoop(session, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        
        // Подписываемся на событие монтирования тома
        DARegisterDiskDescriptionChangedCallback(
            session,
            nil,
            nil,
            { disk, keys, context in
                guard let context = context else { return }
                let service = Unmanaged<USBMonitorService>.fromOpaque(context).takeUnretainedValue()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    service.onDevicesChanged?(service.fetchUSBDevices())
                }
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
    
    func startMonitoring() {
        
        // 1. Создаём порт — это канал связи между IOKit и нашим приложением
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notificationPort else { return }
        
        // 2. Получаем RunLoop source из порта
        // RunLoop — это цикл событий приложения (как main thread loop)
        // Мы говорим: "добавь IOKit события в этот цикл"
        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, CFRunLoopMode.defaultMode)
        
        // 3. Фильтр — те же USB устройства что и раньше
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        
        // 4. self передаём как context — чтобы внутри C callback достучаться до класса
        
        // Правильный способ передать self в C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        // 5. Подписываемся на подключение устройства
        // kIOMatchedNotification — событие "устройство подключено"
        IOServiceAddMatchingNotification(
            port,
            kIOMatchedNotification,
            matchingDict,
            { context, iterator in
                // Это C callback — не может захватывать self напрямую
                // Поэтому достаём self из context
                guard let context = context else { return }
                let service = Unmanaged<USBMonitorService>.fromOpaque(context).takeUnretainedValue()
                service.deviceConnected(iterator)
            },
            selfPtr,
            &addedIterator
        )
        
        // 6. Подписываемся на отключение устройства
        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            IOServiceMatching(kIOUSBDeviceClassName), // нужен новый dict — первый уже consumed
            { context, iterator in
                guard let context = context else { return }
                let service = Unmanaged<USBMonitorService>.fromOpaque(context).takeUnretainedValue()
                service.deviceDisconnected(iterator)
            },
            selfPtr,
            &removedIterator
        )
        
        // 7. ВАЖНО — первый вызов чтобы "слить" начальные устройства
        // IOKit сразу заполняет iterator существующими устройствами
        // Если не вызвать — уведомления не начнут приходить
        deviceConnected(addedIterator)
        deviceDisconnected(removedIterator)
        startVolumeMonitoring()
    }
    
    func stopMonitoring() {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        
        if let port = notificationPort {
            IONotificationPortDestroy(port)
        }
        
        notificationPort = nil
        addedIterator = 0
        removedIterator = 0
    }
    
    
    private func deviceConnected(_ iterator: io_iterator_t) {
  
        // Обходим все новые устройства из iterator
        var device = IOIteratorNext(iterator)
        while device != 0 {
            
            // Fetching USB device name to display in notification
            var properties: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0)
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                let name = dict[kUSBProductString] as? String ?? "USB Device"
                NotificationService.shared.sendNotification(title: "Device Connected", body: name)
            }
            // здесь парсим USBDevice как раньше
            IOObjectRelease(device)
            device = IOIteratorNext(iterator)
        }
        
        // Сообщаем наружу что список изменился
        onDevicesChanged?(fetchUSBDevices())
    }
    
    private func deviceDisconnected(_ iterator: io_iterator_t) {
        // Просто сливаем iterator — устройство уже отключено
        // свойства читать уже нельзя
        var device = IOIteratorNext(iterator)
        while device != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0)
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                let name = dict[kUSBProductString] as? String ?? "USB Device"
                NotificationService.shared.sendNotification(title: "Device Disconnected", body: name)
            }
            IOObjectRelease(device)
            device = IOIteratorNext(iterator)
        }
        
        // Ждём пока тома смонтируются
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.onDevicesChanged?(self.fetchUSBDevices())
        }
    }
    
    
    func fetchUSBDevices() -> [USBDevice] {
        
        var devices: [USBDevice] = []
        
        // 1. Создаём фильтр — "ищи только USB устройства"
        // kIOUSBDeviceClassName — константа IOKit, означает класс USB устройств
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        
        // 2. iterator — это "курсор" по списку найденных устройств
        var iterator: io_iterator_t = 0
        
        // 3. Передаём фильтр — IOKit заполняет iterator найденными устройствами
        // kIOMainPortDefault — главный порт связи с IOKit (просто всегда так)
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        // 4. Проверяем что всё прошло успешно
        guard result == KERN_SUCCESS else {
            return []
        }
        
        // 5. Обходим устройства одно за одним
        // IOIteratorNext возвращает 0 когда устройства закончились
        var device: io_service_t = IOIteratorNext(iterator)
        
        while device != 0 {
            
            // 6. Читаем ВСЕ свойства устройства в словарь
            var properties: Unmanaged<CFMutableDictionary>?
            
            IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0)
            
            // 7. Конвертируем из CFDictionary в Swift Dictionary
            if let dict = properties?.takeRetainedValue() as? [String: Any] {
                
                let name = dict[kUSBProductString] as? String ?? "Unknown"
                let vendorName  = dict[kUSBVendorString]  as? String ?? "Unknown"
                let serialNumber = dict[kUSBSerialNumberString] as? String ?? "Unknown"
                let vendorId = dict["idVendor"] as? Int ?? 0
                let productId = dict["idProduct"] as? Int ?? 0
                let usbVersion = dict["bcdUSB"] as? Int ?? 0
                let speedMbps = dict["USBSpeed"] as? Int ?? 0
                let powerMA = dict["UsbPowerSinkAllocation"] as? Int ?? 0
                let locationID = dict["locationID"] as? Int ?? 0
                let mounted = (try? volumeService.fetchVolumes(for: locationID)) ?? []
                let unmounted = volumeService.fetchUnmountedVolumes(for: locationID)
                let volumes = mounted + unmounted
                
                let tmpDevice = USBDevice(
                    name: name,
                    serialNumber: serialNumber,
                    vendorName: vendorName,
                    vendorID: UInt16(vendorId),
                    productID: UInt16(productId),
                    bcdUSB: usbVersion,
                    usbSpeedIndex: speedMbps,
                    powerMA: powerMA,
                    volumes: volumes
                )
                
                devices.append(tmpDevice)
                
            }
            
            // 8. Releasing memory
            // IOKit is C API — ARC doesn't work here
            IOObjectRelease(device)
            
            // 9. Переходим к следующему устройству
            device = IOIteratorNext(iterator)
        }
        
        // 10. Release iterator itself
        IOObjectRelease(iterator)
        return devices
    }
}
