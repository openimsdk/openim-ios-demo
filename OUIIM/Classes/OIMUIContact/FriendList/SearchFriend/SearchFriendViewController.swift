
import RxSwift
import OUICore
import OUICoreView

class SearchFriendViewController: UIViewController {
    
    var didSelectedItem: ((_ ID: String) -> Void)?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        definesPresentationContext = true
        navigationItem.title = "addFriend".innerLocalized()
        
        let resultViewController = SearchResultViewController(searchType: .user)
        let searchViewController = UISearchController(searchResultsController: resultViewController)
        searchViewController.searchResultsUpdater = resultViewController
        searchViewController.searchBar.placeholder = "addFriendHint".innerLocalized()
        searchViewController.obscuresBackgroundDuringPresentation = false
        searchViewController.hidesNavigationBarDuringPresentation = false
        searchViewController.automaticallyShowsCancelButton = false
        searchViewController.delegate = self

        navigationItem.searchController = searchViewController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        resultViewController.didSelectedItem = didSelectedItem
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.searchController?.isActive = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
}

extension SearchFriendViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}
