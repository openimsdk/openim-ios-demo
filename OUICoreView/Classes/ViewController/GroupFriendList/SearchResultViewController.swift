import OUICore
import RxSwift
import SnapKit

public class SearchResultViewController: UIViewController, UISearchResultsUpdating {
    
    public var didSelectedItem: ((_ ID: String) -> Void)?
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.className)
        v.rowHeight = UITableView.automaticDimension
        v.dataSource = self
        v.delegate = self
        v.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private lazy var searchResultEmptyView: UIView = {
        let v = UIView()
        let label: UILabel = {
            let v = UILabel()
            v.text = "noFoundX".innerLocalizedFormat(arguments: _searchType.title)
            v.textColor = .c8E9AB0
            v.font = .f17
            
            return v
        }()
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        v.isHidden = true
        return v
    }()
    
    private var debounceTimer: Timer?
    var dataList = [[String: String]]() {
        willSet {
            dataList = newValue
            tableView.reloadData()
        }
    }
    private let _disposebag = DisposeBag()
    private let _searchType: SearchType
    private var userInfo: PublicUserInfo?
    public init(searchType: SearchType) {
        _searchType = searchType
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
    }
    
    private func initView() {
        view.backgroundColor = .groupTableViewBackground
        definesPresentationContext = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.bottom.trailing.equalToSuperview()
        }
        
        view.addSubview(searchResultEmptyView)
        searchResultEmptyView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(38.h)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
    }
    
    private func bindData() {
    }
    
    public enum SearchType {

        case group

        case user
        
        var title: String {
            switch self {
            case .group:
                return "群组".innerLocalized()
            case .user:
                return "用户".innerLocalized()
            }
        }
    }
    
    private var keyword: String = ""
    
    public func updateSearchResults(for searchController: UISearchController) {
        let keyword = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let keyword = keyword, !keyword.isEmpty else {
            return
        }
        
        search(keyword)
    }
    
    @objc func search(_ keyword: String) {
        
        self.keyword = keyword
        
        switch _searchType {
        case .group:
            IMController.shared.getGroupListBy(id: keyword).subscribe(onNext: { [weak self] (groupID: String?) in
                let shouldHideEmptyView = groupID != nil
                let shouldHideResultView = groupID == nil
                DispatchQueue.main.async {
                    self?.searchResultEmptyView.isHidden = shouldHideEmptyView
                    self?.tableView.isHidden = shouldHideResultView
                    if groupID != nil {
                        self?.dataList = [[groupID!: groupID!]]
                    }
                }
            }).disposed(by: _disposebag)
        case .user:

            if let handler = OIMApi.queryFriendsWithCompletionHandler {
                handler([keyword], {res in
                    let shouldHideEmptyView = !res.isEmpty
                    let shouldHideResultView = res.isEmpty
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.searchResultEmptyView.isHidden = shouldHideEmptyView
                        self.tableView.isHidden = shouldHideResultView

                        let isNumber = keyword.trimmingCharacters(in: .decimalDigits).count == 0
                        let isPhone = self.isPhoneNumber(keyword)
                        let isEmail = self.isEmail(keyword)
                        
                        self.dataList = res.map { elem in
                            if isNumber {
                                if isPhone {
                                    return [elem.userID : "手机号".innerLocalized() + ":" + elem.phoneNumber!]
                                } else {
                                    return [elem.userID : "ID:" + elem.userID]
                                }
                            } else if isEmail {
                                return [elem.userID : "邮箱".innerLocalized() + ":" + elem.email!]
                            } else {
                                return [elem.userID : "昵称".innerLocalized() + ":" + elem.nickname!]
                            }
                        }
                    }
                })
            } else {
                IMController.shared.getFriendsBy(id: keyword).subscribe { [weak self] userInfo in
                    self?.userInfo = userInfo
                    let uid = userInfo?.userID
                    let shouldHideEmptyView = uid != nil
                    let shouldHideResultView = uid == nil
                    DispatchQueue.main.async {
                        self?.searchResultEmptyView.isHidden = shouldHideEmptyView
                        self?.tableView.isHidden = shouldHideResultView
                        
                        if uid != nil {
                            self?.dataList = [[uid! :uid!]]
                        }
                    }
                }.disposed(by: _disposebag)
            }
        }
    }
    
    deinit {
        debounceTimer = nil
    }

    func isEmail(_ email: String) -> Bool {
        if email.count == 0 {
            return false
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest:NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }

    func isPhoneNumber(_ phoneNumber: String) -> Bool {
        if phoneNumber.count == 0 {
            return false
        }
        let mobile = "^1([358][0-9]|4[579]|66|7[0135678]|9[89])[0-9]{8}$"
        let regexMobile = NSPredicate(format: "SELF MATCHES %@",mobile)
        if regexMobile.evaluate(with: phoneNumber) == true {
            return true
        } else {
            return false
        }
    }
}

extension SearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return dataList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.className, for: indexPath) as! SearchResultCell
        let info = dataList[indexPath.row]
        
        let text = info.values.first
        cell.titleLabel.text = text
        
        return cell
    }
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let info = dataList[indexPath.row]
        if let id = info.keys.first {
            didSelectedItem?(id)
        }
    }
}
