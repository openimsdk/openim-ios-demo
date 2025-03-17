
import OUICore

public class PopoverTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    public struct MenuItem {
        let title: String
        let icon: UIImage?
        let action: () -> Void
        public init(title: String, icon: UIImage?, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
    
    public func show<T>(in baseController: T, sender: UIView? = nil, itemSender: UIBarButtonItem? = nil, permittedArrowDirections: UIPopoverArrowDirection = .any, sourceViewReviseOffset: CGFloat = 100.h) where T: UIViewController {
        assert(sender != nil || itemSender != nil)
        DispatchQueue.main.async { [self] in 
            self.modalPresentationStyle = .popover
            let popoverPresentationController = self.popoverPresentationController
            popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
            if let sender {
                popoverPresentationController?.sourceView = sender
                
                var rect = sender.bounds

                if permittedArrowDirections.isEmpty {
                    rect = CGRect(origin: CGPoint(x: rect.midX, y: rect.maxY + sourceViewReviseOffset), size: rect.size)
                }
                
                popoverPresentationController?.sourceRect = rect
            } else {
                popoverPresentationController?.barButtonItem = itemSender
            }
            popoverPresentationController?.delegate = self
            
            baseController.present(self, animated: true, completion: nil)
        }
    }
    
    public init(items: [MenuItem] = []) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
    }
    
    public var items: [MenuItem] = [] {
        didSet {
            preferredContentSize = CGSize(width: itemSize.width, height: CGFloat(items.count) * itemSize.height + CGFloat(Int(topInset / 2.0)))
            tableView.reloadData()
        }
    }
    
    public var topInset = 14.0.h
    
    public var itemSize: CGSize = CGSize(width: 160.w, height: 40.h)
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.dataSource = self
        v.delegate = self
        v.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        v.rowHeight = itemSize.height
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isScrollEnabled = false
        
        return v
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        preferredContentSize = CGSize(width: itemSize.width, height: CGFloat(items.count) * itemSize.height + CGFloat(Int(topInset / 2.0)))
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let item = items[indexPath.row]
        
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = .c0C1C33
        cell.textLabel?.font = .f17
        cell.imageView?.image = item.icon
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.action()
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

extension PopoverTableViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
}
