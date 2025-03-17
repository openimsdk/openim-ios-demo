

























import Foundation

private class BundleFinder {}

extension Bundle {
    private static var bundle: Bundle?
    
    static var normalModule: Bundle? = {
        let bundleName = "ZLPhotoBrowser"

        var candidates = [

            Bundle.main.resourceURL,

            Bundle(for: ZLPhotoPreviewSheet.self).resourceURL,

            Bundle.main.bundleURL
        ]
        
        #if SWIFT_PACKAGE

            candidates.append(Bundle.module.bundleURL)
        #endif

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    
    static var spmModule: Bundle? = {
        let bundleName = "ZLPhotoBrowser_ZLPhotoBrowser"

        let candidates = [

            Bundle.main.resourceURL,

            Bundle(for: BundleFinder.self).resourceURL,

            Bundle.main.bundleURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    
    static var zlPhotoBrowserBundle: Bundle? {
        return normalModule ?? spmModule
    }
    
    class func resetLanguage() {
        bundle = nil
    }
    
    class func zlLocalizedString(_ key: String) -> String {
        if bundle == nil {
            guard let path = Bundle.zlPhotoBrowserBundle?.path(forResource: ZLCustomLanguageDeploy.language.key, ofType: "lproj") else {
                return ""
            }
            bundle = Bundle(path: path)
        }
        
        let value = bundle?.localizedString(forKey: key, value: nil, table: nil)
        return Bundle.main.localizedString(forKey: key, value: value, table: nil)
    }
}
