import RxSwift
import OUICore

public class SearchGroupViewController: UIViewController {
    
    public var didSelectedItem: ((_ groupID: String) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        definesPresentationContext = true
        navigationItem.title = "addGroup".innerLocalized()
        
        let resultViewController = SearchResultViewController(searchType: .group)
        let searchViewController = UISearchController(searchResultsController: resultViewController)
        searchViewController.searchResultsUpdater = resultViewController
        searchViewController.searchBar.placeholder = "searchIDAddGroup".innerLocalized()
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

extension SearchGroupViewController: UISearchControllerDelegate {
    public func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}
