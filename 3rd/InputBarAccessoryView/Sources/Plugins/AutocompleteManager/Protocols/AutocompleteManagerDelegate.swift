


























import UIKit

public protocol AutocompleteManagerDelegate: AnyObject {





    func autocompleteManager(_ manager: AutocompleteManager, shouldBecomeVisible: Bool)







    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool







    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool







    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool
    
    
    func autocompleteManager(_ manager: AutocompleteManager, didRemove completion: AutocompleteCompletion?)
}

public extension AutocompleteManagerDelegate {
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldRegister prefix: String, at range: NSRange) -> Bool {
        return true
    }
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldUnregister prefix: String) -> Bool {
        return true
    }
    
    func autocompleteManager(_ manager: AutocompleteManager, shouldComplete prefix: String, with text: String) -> Bool {
        return true
    }
    
    func autocompleteManager(_ manager: AutocompleteManager, didRemove completion: AutocompleteCompletion?) {}
}

