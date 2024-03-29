//
//  Keychain.swift
//
// Copyright (c) 2016-2018年 Mantis Group. All rights reserved.
//

import UIKit
import Security


/**
 A collection of helper functions for saving text and data in the keychain.
 */
open class KeychainSwift {
    
    var lastQueryParameters: [String: Any]? // Used by the unit tests
    
    var keyPrefix = "" // Can be useful in test.
    
    public init() { }
    
    /**
     
     - parameter keyPrefix: a prefix that is added before the key in get/set methods. Note that `clear` method still clears everything from the Keychain.
     */
    public init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
    }
    
    /**
     
     Stores the text value in the keychain item under the given key.
     
     - parameter key: Key under which the text value is stored in the keychain.
     - parameter value: Text string to be written to the keychain.
     - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
     */
    @discardableResult
    open func set(_ value: String, forKey key: String,
        withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
            
            if let value = value.data(using: String.Encoding.utf8) {
                return set(value, forKey: key, withAccess: access)
            }
            
            return false
    }
    
    /**
     
     Stores the data in the keychain item under the given key.
     
     - parameter key: Key under which the data is stored in the keychain.
     - parameter value: Data to be written to the keychain.
     - parameter withAccess: Value that indicates when your app needs access to the text in the keychain item. By default the .AccessibleWhenUnlocked option is used that permits the data to be accessed only while the device is unlocked by the user.
     
     - returns: True if the text was successfully written to the keychain.
     
     */
    @discardableResult
    open func set(_ value: Data, forKey key: String,
        withAccess access: KeychainSwiftAccessOptions? = nil) -> Bool {
            
            let accessible = access?.value ?? KeychainSwiftAccessOptions.defaultOption.value
            
            let prefixedKey = keyWithPrefix(key)
            
            let query = [
                KeychainSwiftConstants.klass       : KeychainSwiftConstants.classGenericPassword,
                KeychainSwiftConstants.attrAccount : prefixedKey,
                KeychainSwiftConstants.valueData   : value,
                KeychainSwiftConstants.accessible  : accessible
            ] as [String : Any]
            
            lastQueryParameters = query
            
            SecItemDelete(query as CFDictionary)
            
            let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
            
            return status == noErr
    }
    
    /**
     
     Retrieves the text value from the keychain that corresponds to the given key.
     
     - parameter key: The key that is used to read the keychain item.
     - returns: The text value from the keychain. Returns nil if unable to read the item.
     
     */
    open func get(_ key: String) -> String? {
        if let data = getData(key),
            let currentString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
                
                return currentString
        }
        
        return nil
    }
    
    /**
     
     Retrieves the data from the keychain that corresponds to the given key.
     
     - parameter key: The key that is used to read the keychain item.
     - returns: The text value from the keychain. Returns nil if unable to read the item.
     
     */
    open func getData(_ key: String) -> Data? {
        let prefixedKey = keyWithPrefix(key)
        
        let query = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey,
            KeychainSwiftConstants.returnData  : kCFBooleanTrue,
            KeychainSwiftConstants.matchLimit  : kSecMatchLimitOne ] as [String : Any]
        
        var result: AnyObject?
        
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if status == noErr { return result as? Data }
        
        return nil
    }
    
    /**
     
     Deletes the single keychain item specified by the key.
     
     - parameter key: The key that is used to delete the keychain item.
     - returns: True if the item was successfully deleted.
     
     */
    @discardableResult
    open func delete(_ key: String) -> Bool {
        let prefixedKey = keyWithPrefix(key)
        
        let query = [
            KeychainSwiftConstants.klass       : kSecClassGenericPassword,
            KeychainSwiftConstants.attrAccount : prefixedKey ] as [String : Any]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
    
    /**
     
     Deletes all Keychain items used by the app. Note that this method deletes all items regardless of the prefix settings used for initializing the class.
     
     - returns: True if the keychain items were successfully deleted.
     
     */
    @discardableResult
    open func clear() -> Bool {
        let query = [ kSecClass as String : kSecClassGenericPassword ]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        return status == noErr
    }
    
    /// Returns the key with currently set prefix.
    func keyWithPrefix(_ key: String) -> String {
        return "\(keyPrefix)\(key)"
    }
}


// ----------------------------
//
// KeychainSwiftAccessOptions.swift
//
// ----------------------------

import Security

/**
 These options are used to determine when a keychain item should be readable. The default value is AccessibleWhenUnlocked.
 */
public enum KeychainSwiftAccessOptions {
    
    /**
     
     The data in the keychain item can be accessed only while the device is unlocked by the user.
     
     This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute migrate to a new device when using encrypted backups.
     
     This is the default value for keychain items added without explicitly setting an accessibility constant.
     
     */
    case accessibleWhenUnlocked
    
    /**
     
     The data in the keychain item can be accessed only while the device is unlocked by the user.
     
     This is recommended for items that need to be accessible only while the application is in the foreground. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
     
     */
    case accessibleWhenUnlockedThisDeviceOnly
    
    /**
     
     The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
     
     After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute migrate to a new device when using encrypted backups.
     
     */
    case accessibleAfterFirstUnlock
    
    /**
     
     The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
     
     After the first unlock, the data remains accessible until the next restart. This is recommended for items that need to be accessed by background applications. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
     
     */
    case accessibleAfterFirstUnlockThisDeviceOnly
    
    /**
     
     The data in the keychain item can always be accessed regardless of whether the device is locked.
     
     This is not recommended for application use. Items with this attribute migrate to a new device when using encrypted backups.
     
     */
    case accessibleAlways
    
    /**
     
     The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
     
     This is recommended for items that only need to be accessible while the application is in the foreground. Items with this attribute never migrate to a new device. After a backup is restored to a new device, these items are missing. No items can be stored in this class on devices without a passcode. Disabling the device passcode causes all items in this class to be deleted.
     
     */
    case accessibleWhenPasscodeSetThisDeviceOnly
    
    /**
     
     The data in the keychain item can always be accessed regardless of whether the device is locked.
     
     This is not recommended for application use. Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
     
     */
    case accessibleAlwaysThisDeviceOnly
    
    static var defaultOption: KeychainSwiftAccessOptions {
        return .accessibleWhenUnlocked
    }
    
    var value: String {
        switch self {
        case .accessibleWhenUnlocked:
            return toString(kSecAttrAccessibleWhenUnlocked)
            
        case .accessibleWhenUnlockedThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            
        case .accessibleAfterFirstUnlock:
            return toString(kSecAttrAccessibleAfterFirstUnlock)
            
        case .accessibleAfterFirstUnlockThisDeviceOnly:
            return toString(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
            
        case .accessibleAlways:
            return toString(kSecAttrAccessibleAlways)
            
        case .accessibleWhenPasscodeSetThisDeviceOnly:
            return toString(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
            
        case .accessibleAlwaysThisDeviceOnly:
            return toString(kSecAttrAccessibleAlwaysThisDeviceOnly)
        }
    }
    
    func toString(_ value: CFString) -> String {
        return KeychainSwiftConstants.toString(value)
    }
}


// ----------------------------
//
// TegKeychainConstants.swift
//
// ----------------------------

import Foundation
import Security

public struct KeychainSwiftConstants {
    public static var klass: String { return toString(kSecClass) }
    public static var classGenericPassword: String { return toString(kSecClassGenericPassword) }
    public static var attrAccount: String { return toString(kSecAttrAccount) }
    public static var valueData: String { return toString(kSecValueData) }
    public static var returnData: String { return toString(kSecReturnData) }
    public static var matchLimit: String { return toString(kSecMatchLimit) }
    
    /**
     
     A value that indicates when your app needs access to the data in a keychain item. The default value is AccessibleWhenUnlocked. For a list of possible values, see KeychainSwiftAccessOptions.
     
     */
    public static var accessible: String { return toString(kSecAttrAccessible) }
    
    static func toString(_ value: CFString) -> String {
        return value as String
    }
}
