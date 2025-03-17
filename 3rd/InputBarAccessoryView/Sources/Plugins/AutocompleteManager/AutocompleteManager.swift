


























import UIKit

public extension NSAttributedString.Key {


    static let autocompleted = NSAttributedString.Key("com.system.autocompletekey")


    static let autocompletedContext = NSAttributedString.Key("com.system.autocompletekey.context")
}

open class AutocompleteManager: NSObject, InputPlugin, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {


    open weak var dataSource: AutocompleteManagerDataSource?

    open weak var delegate: AutocompleteManagerDelegate?

    private(set) public weak var textView: UITextView?
    
    @available(*, deprecated, message: "`inputTextView` has been renamed to `textView` of type `UITextView`")
    public var inputTextView: InputTextView? { return textView as? InputTextView }

    private(set) public var currentSession: AutocompleteSession?

    open lazy var tableView: AutocompleteTableView = { [weak self] in
        let tableView = AutocompleteTableView()
        tableView.register(AutocompleteCell.self, forCellReuseIdentifier: AutocompleteCell.reuseIdentifier)
        tableView.separatorStyle = .none
        if #available(iOS 13, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }
        tableView.rowHeight = 44
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()


    open var appendSpaceOnCompletion = true


    open var keepPrefixOnCompletion = true







    open var maxSpaceCountDuringCompletion: Int = 0





    open var deleteCompletionByParts = true

    open var defaultTextAttributes: [NSAttributedString.Key: Any] = {
        var foregroundColor: UIColor
        if #available(iOS 13, *) {
            foregroundColor = .label
        } else {
            foregroundColor = .black
        }
        return [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: foregroundColor]
    }()

    public let paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = 2
        style.lineHeightMultiple = 1
        return style
    }()





    open var filterBlock: (AutocompleteSession, AutocompleteCompletion) -> (Bool) = { session, completion in completion.text.lowercased().contains(session.filter.lowercased())
    }


    public private(set) var autocompletePrefixes = Set<String>()


    public private(set) var autocompleteDelimiterSets: Set<CharacterSet> = [.whitespaces, .newlines]

    public private(set) var autocompleteTextAttributes = [String: [NSAttributedString.Key: Any]]()
    
    private var lastEntered: String?

    private var typingTextAttributes: [NSAttributedString.Key: Any] {
        var attributes = defaultTextAttributes
        attributes[.autocompleted] = false
        attributes[.autocompletedContext] = nil
        attributes[.paragraphStyle] = paragraphStyle
        return attributes
    }

    private var currentAutocompleteOptions: [AutocompleteCompletion] {
        
        guard let session = currentSession, let completions = dataSource?.autocompleteManager(self, autocompleteSourceFor: session.prefix) else { return [] }
        guard !session.filter.isEmpty else { return completions }
        
        return completions.filter { completion in
            return filterBlock(session, completion)
        }
    }

    
    public init(for textView: UITextView) {
        super.init()
        self.textView = textView
        self.textView?.delegate = self
    }


    open func reloadData() {

        var delimiterSet = autocompleteDelimiterSets.reduce(CharacterSet()) { result, set in
            return result.union(set)
        }
        let query = textView?.find(prefixes: autocompletePrefixes, with: delimiterSet)
        
        guard let result = query else {
            if let session = currentSession, session.spaceCounter <= maxSpaceCountDuringCompletion {
                delimiterSet = delimiterSet.subtracting(.whitespaces)
                guard let result = textView?.find(prefixes: [session.prefix], with: delimiterSet) else {
                    unregisterCurrentSession()
                    return
                }
                let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
                updateCurrentSession(to: wordWithoutPrefix)
            } else {
                unregisterCurrentSession()
            }
            return
        }
        let wordWithoutPrefix = (result.word as NSString).substring(from: result.prefix.utf16.count)
        
        guard let session = AutocompleteSession(prefix: result.prefix, range: result.range, filter: wordWithoutPrefix) else { return }
        
        guard let currentSession = currentSession else {
            registerCurrentSession(to: session)
            return
        }
        if currentSession == session {
            updateCurrentSession(to: wordWithoutPrefix)
        } else {
            registerCurrentSession(to: session)
        }
    }

    open func invalidate() {
        unregisterCurrentSession()
    }



    @discardableResult
    open func handleInput(of object: AnyObject) -> Bool {
        guard let newText = object as? String, let textView = textView else { return false }
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
        let newAttributedString = NSAttributedString(string: newText, attributes: typingTextAttributes)
        attributedString.append(newAttributedString)
        textView.attributedText = attributedString
        reloadData()
        return true
    }






    open func register(prefix: String, with attributedTextAttributes: [NSAttributedString.Key:Any]? = nil) {
        autocompletePrefixes.insert(prefix)
        autocompleteTextAttributes[prefix] = attributedTextAttributes
        autocompleteTextAttributes[prefix]?[.paragraphStyle] = paragraphStyle
    }



    open func unregister(prefix: String) {
        autocompletePrefixes.remove(prefix)
        autocompleteTextAttributes[prefix] = nil
    }



    open func register(delimiterSet set: CharacterSet) {
        autocompleteDelimiterSets.insert(set)
    }



    open func unregister(delimiterSet set: CharacterSet) {
        autocompleteDelimiterSets.remove(set)
    }




    open func autocomplete(with session: AutocompleteSession) {
        
        guard let textView = textView else { return }
        guard delegate?.autocompleteManager(self, shouldComplete: session.prefix, with: session.filter) != false else { return }

        let prefixLength = session.prefix.utf16.count
        let insertionRange = NSRange(
            location: session.range.location + (keepPrefixOnCompletion ? prefixLength : 0),
            length: session.filter.utf16.count + (!keepPrefixOnCompletion ? prefixLength : 0)
        )

        guard let range = Range(insertionRange, in: textView.text) else { return }
        let nsrange = NSRange(range, in: textView.text)

        let autocomplete = session.completion?.text ?? ""
        insertAutocomplete(autocomplete, at: session, for: nsrange)

        let selectedLocation = insertionRange.location + autocomplete.utf16.count + (appendSpaceOnCompletion ? 1 : 0)
        textView.selectedRange = NSRange(
            location: selectedLocation,
            length: 0
        )

        unregisterCurrentSession()
    }
    
    open func submitMultipleCompletions(with completions: [AutocompleteCompletion], prefix: String = "@") {
        for (_, completion) in completions.enumerated() {
            if currentSession == nil {
                let attributedText = NSMutableAttributedString(attributedString: textView!.attributedText)
                
                let mentionFlag = currentSession?.prefix ?? prefix
                var attrs = autocompleteTextAttributes[mentionFlag] ?? defaultTextAttributes
                attrs[.autocompleted] = true
                let mentionAttributedText = NSAttributedString(string: mentionFlag, attributes: attrs)
                
                attributedText.append(mentionAttributedText)
                textView!.attributedText = attributedText
                
                preserveTypingAttributes()
                reloadData()
            }
                        
            currentSession!.completion = completion
            autocomplete(with: currentSession!)
        }
    }
    
    open func replaceCompletion(target: String, with completion: AutocompleteCompletion, prefix: String = "@") {
        
        let mentionFlag = currentSession?.prefix ?? prefix
        
        let attributedText = NSMutableAttributedString(attributedString: textView!.attributedText)
        let tempText = attributedText.string
                
        var attrs = autocompleteTextAttributes[mentionFlag] ?? defaultTextAttributes
        attrs[.autocompleted] = true
        attrs[.autocompletedContext] = completion.context
        attrs[.backgroundColor] = UIColor.clear
        let toAttributedString = NSMutableAttributedString(string: target, attributes: attrs)

        var currentIndex = tempText.startIndex
        
        while currentIndex < tempText.endIndex {
            if let range = tempText[currentIndex...].range(of: target, options: .literal) {
                let nsRange = NSRange(range, in: tempText)
                attributedText.addAttributes(attrs, range: nsRange)
                currentIndex = range.upperBound
            } else {
                currentIndex = tempText.index(after: currentIndex)
            }
        }
        
        textView!.attributedText = attributedText
    }




    open func attributedText(matching session: AutocompleteSession,
                             fontSize: CGFloat = 15,
                             keepPrefix: Bool = true) -> NSMutableAttributedString {
        
        guard let completion = session.completion else {
            return NSMutableAttributedString()
        }

        let matchingRange = (completion.text as NSString).range(of: session.filter, options: .caseInsensitive)
        let attributedString = NSMutableAttributedString().normal(completion.text, fontSize: fontSize)
        attributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: fontSize)], range: matchingRange)
        
        guard keepPrefix else { return attributedString }
        let stringWithPrefix = NSMutableAttributedString().normal(String(session.prefix), fontSize: fontSize)
        stringWithPrefix.append(attributedString)
        return stringWithPrefix
    }


    private func preserveTypingAttributes() {
        textView?.typingAttributes = typingTextAttributes
    }






    private func insertAutocomplete(_ autocomplete: String, at session: AutocompleteSession, for range: NSRange) {
        
        guard let textView = textView else { return }

        var attrs = autocompleteTextAttributes[session.prefix] ?? defaultTextAttributes
        attrs[.autocompleted] = true
        attrs[.autocompletedContext] = session.completion?.context
        let newString = (keepPrefixOnCompletion ? session.prefix : "") + autocomplete + (appendSpaceOnCompletion ? " " : "")
        let newAttributedString = NSMutableAttributedString(string: newString, attributes: attrs)





        let rangeModifier = keepPrefixOnCompletion ? session.prefix.count : 0
        let highlightedRange = NSRange(location: range.location - rangeModifier, length: range.length + rangeModifier)

        let newAttributedText = textView.attributedText.replacingCharacters(in: highlightedRange, with: newAttributedString)

        newAttributedText.addAttribute(NSAttributedString.Key.backgroundColor,
                                       value: UIColor.clear,
                                       range: NSMakeRange(0, newAttributedText.length))

        textView.attributedText = NSAttributedString()

        textView.attributedText = newAttributedText
    }




    private func registerCurrentSession(to session: AutocompleteSession) {
        
        guard delegate?.autocompleteManager(self, shouldRegister: session.prefix, at: session.range) != false else { return }
        currentSession = session
        layoutIfNeeded()
        delegate?.autocompleteManager(self, shouldBecomeVisible: true)
    }




    private func updateCurrentSession(to filterText: String) {
        
        currentSession?.filter = filterText
        layoutIfNeeded()
        delegate?.autocompleteManager(self, shouldBecomeVisible: true)
    }

    private func unregisterCurrentSession() {
        
        guard let session = currentSession else { return }
        guard delegate?.autocompleteManager(self, shouldUnregister: session.prefix) != false else { return }

        currentSession = nil
        layoutIfNeeded()
        delegate?.autocompleteManager(self, shouldBecomeVisible: false)
    }

    private func layoutIfNeeded() {
        
        tableView.reloadData()

        tableView.invalidateIntrinsicContentSize()

        tableView.superview?.layoutIfNeeded()
    }
    
    public func resetLastEntered() {
        lastEntered = nil
    }

    
    public func textViewDidChange(_ textView: UITextView) {

        if (lastEntered == nil ||
            lastEntered!.count < textView.text.count),
            let suffix = textView.text.last,
            autocompletePrefixes.contains(String(suffix)) {
            reloadData()
        }
        
        lastEntered = textView.text
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        resetLastEntered()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        preserveTypingAttributes()

        if text.isEmpty {
            lastEntered = (textView.text as NSString).replacingCharacters(in: range, with: text)
        }
        
        if let session = currentSession {
            let textToReplace = (textView.text as NSString).substring(with: range)
            let deleteSpaceCount = textToReplace.filter { $0 == .space }.count
            let insertSpaceCount = text.filter { $0 == .space }.count
            let spaceCountDiff = insertSpaceCount - deleteSpaceCount
            session.spaceCounter = spaceCountDiff
        }
        
        let totalRange = NSRange(location: 0, length: textView.attributedText.length)
        let selectedRange = textView.selectedRange




        if range.length > 0, range.location < selectedRange.location {

            let attributes = textView.attributedText.attributes(at: range.location, longestEffectiveRange: nil, in: range)
            
            let text = textView.attributedText.attributedSubstring(from: range)
            let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
            
            if isAutocompleted {
                textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                    
                    let intersection = NSIntersectionRange(range, subrange)
                    guard intersection.length > 0 else { return }
                    defer { stop.pointee = true }

                    let nothing = NSAttributedString(string: "", attributes: typingTextAttributes)

                    let textToReplace = textView.attributedText.attributedSubstring(from: subrange).string







                    guard deleteCompletionByParts, let delimiterRange = textToReplace.range(of: currentSession?.prefix ?? "@", options: .backwards) else {

                        textView.attributedText = textView.attributedText.replacingCharacters(in: subrange, with: nothing)
                        textView.selectedRange = NSRange(location: subrange.location, length: 0)
                        
                        delegate?.autocompleteManager(self, didRemove: currentSession?.completion)
                        lastEntered = textView.attributedText.string

                        return
                    }

                    let delimiterLocation = delimiterRange.lowerBound.utf16Offset(in: textToReplace)
                    let length = subrange.length - delimiterLocation
                    let rangeFromDelimiter = NSRange(location: delimiterLocation + subrange.location, length: length)
                    textView.attributedText = textView.attributedText.replacingCharacters(in: rangeFromDelimiter, with: nothing)
                    textView.selectedRange = NSRange(location: subrange.location + delimiterLocation, length: 0)
                }
                delegate?.autocompleteManager(self, didRemove: currentSession?.completion)
                lastEntered = textView.attributedText.string
                
                unregisterCurrentSession()
                return false
            }
        } else if range.length > 0, range.location < totalRange.length { // MODIFY: range.length >= 0

            guard range.location != 0 else { return true }

            let attributes = textView.attributedText.attributes(at: range.location-1, longestEffectiveRange: nil, in: NSMakeRange(range.location-1, range.length))

            let isAutocompleted = attributes[.autocompleted] as? Bool ?? false
            if isAutocompleted {
                textView.attributedText.enumerateAttribute(.autocompleted, in: totalRange, options: .reverse) { _, subrange, stop in
                    
                    let compareRange = range.length == 0 ? NSRange(location: range.location, length: 1) : range
                    let intersection = NSIntersectionRange(compareRange, subrange)
                    guard intersection.length > 0 else { return }
                    
                    let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
                    mutable.setAttributes(typingTextAttributes, range: subrange)
                    let replacementText = NSAttributedString(string: text, attributes: typingTextAttributes)
                    textView.attributedText = mutable.replacingCharacters(in: range, with: replacementText)
                    textView.selectedRange = NSRange(location: range.location + text.count, length: 0)
                    stop.pointee = true
                }
                lastEntered = textView.attributedText.string
                unregisterCurrentSession()
                return false
            }
        }
        return true
    }

    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentAutocompleteOptions.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let session = currentSession else { fatalError("Attempted to render a cell for a nil `AutocompleteSession`") }
        session.completion = currentAutocompleteOptions[indexPath.row]
        guard let cell = dataSource?.autocompleteManager(self, tableView: tableView, cellForRowAt: indexPath, for: session) else {
            fatalError("Failed to return a cell from `dataSource: AutocompleteManagerDataSource`")
        }
        return cell
    }

    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let session = currentSession else { return }
        
        let completion = currentAutocompleteOptions[indexPath.row]
        session.completion = completion
        autocomplete(with: session)
    }
    
}
