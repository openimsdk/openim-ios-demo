


























import UIKit

public protocol AutocompleteManagerDataSource: AnyObject {






    func autocompleteManager(_ manager: AutocompleteManager, autocompleteSourceFor prefix: String) -> [AutocompleteCompletion]








    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell
}

public extension AutocompleteManagerDataSource {
    
    func autocompleteManager(_ manager: AutocompleteManager, tableView: UITableView, cellForRowAt indexPath: IndexPath, for session: AutocompleteSession) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AutocompleteCell.reuseIdentifier, for: indexPath) as? AutocompleteCell else {
            fatalError("AutocompleteCell is not registered")
        }
        
        cell.textLabel?.attributedText = manager.attributedText(matching: session, fontSize: 13)
        if #available(iOS 13, *) {
            cell.backgroundColor = .systemBackground
        } else {
            cell.backgroundColor = .white
        }
        cell.separatorLine.isHidden = tableView.numberOfRows(inSection: indexPath.section) - 1 == indexPath.row
        return cell
        
    }
    
}
