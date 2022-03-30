//
//  PreviewViewController.swift
//  ZipQuickLook
//
//  Created by sonson on 2021/02/03.
//

import Cocoa
import Quartz
import ZIPFoundation

@objc public class Node: NSObject {

    @objc let value: String
    @objc var children: [Node]
    
    let entry: ZIPFoundation.Entry?

    @objc var childrenCount: String? {
        let count = children.count
        guard count > 0 else { return nil }
        return "\(count) node\(count > 1 ? "s" : "")"
    }

    @objc var count: Int {
        children.count
    }

    @objc var isLeaf: Bool {
        children.isEmpty
    }

    init(value: String, children: [Node] = [], entry: Entry? = nil) {
        self.entry = entry
        self.value = value
        self.children = children
    }
}


class PreviewViewController: NSViewController, QLPreviewingController, NSOutlineViewDelegate {
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var outlineView: NSOutlineView!
    private let treeController = NSTreeController()
    @objc dynamic var content = [Node]()
    
    var archive: Archive?
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
    
    override func keyDown(with event: NSEvent) {
        if (event.keyCode == 1){
             print("down")
        }
    }

    override func keyUp(with event: NSEvent) {
          if (event.keyCode == 1){
             print("up")
        }
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        print(#function)
        
        
        
        if let index = outlineView.selectedRowIndexes.first {
            if let obj = outlineView.item(atRow: index) as? NSTreeNode {
                if let node = obj.representedObject as? Node {
                    print(node.entry?.path)
                    if let archive = self.archive {
                        if let entry = node.entry {
                            do {
                                var d = Data()
                                _ = try archive.extract(entry, bufferSize: 20480, skipCRC32: true, progress: nil, consumer: { (data) in
                                    print("read from zip file - " + String(data.count))
                                    d.append(data)
                                })
                                
                                if let image = NSImage(data: d) {
                                    imageView.image = image
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
        }
//        if let node = treeController.selectedNodes.first {
////            print(node)
//            if let a = treeController.arrangedObjects.children?[0] {
//                if let b = a.children?[0] {
//                    print(b.children?[index])
//                    if let c = b.children?[index] {
//                        let d = c.representedObject
//                        print(d)
//                    }
//
//                }
//            }
//        }
    }
    
    public func outlineView(_ outlineView: NSOutlineView,
                            viewFor tableColumn: NSTableColumn?,
                            item: Any) -> NSView? {
        var cellView: NSTableCellView?

        guard let identifier = tableColumn?.identifier else { return cellView }
        
        switch identifier {
        case .init("node"):
            if let view = outlineView.makeView(withIdentifier: identifier,
                                               owner: outlineView.delegate) as? NSTableCellView {
                view.textField?.bind(.value,
                                     to: view,
                                     withKeyPath: "objectValue.value",
                                     options: nil)
                cellView = view
            }
        case .init("count"):
            if let view = outlineView.makeView(withIdentifier: identifier,
                                               owner: outlineView.delegate) as? NSTableCellView {
                view.textField?.bind(.value,
                                     to: view,
                                     withKeyPath: "objectValue.childrenCount",
                                     options: nil)
                cellView = view
            }
        default:
            return cellView
        }
        return cellView
    }
    
    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        
        outlineView.delegate = self

        treeController.objectClass = Node.self
        treeController.childrenKeyPath = "children"
        treeController.countKeyPath = "count"
        treeController.leafKeyPath = "isLeaf"

        outlineView.gridStyleMask = .solidHorizontalGridLineMask
        outlineView.autosaveExpandedItems = true

        treeController.bind(NSBindingName(rawValue: "contentArray"),
                            to: self,
                            withKeyPath: "content",
                            options: nil)


        outlineView.bind(NSBindingName(rawValue: "content"),
                         to: treeController,
                         withKeyPath: "arrangedObjects",
                         options: nil)

        
        
//        content.append(contentsOf: NodeFactory().nodes())
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
        guard let tmp = Archive(url: url, accessMode: .read, preferredEncoding: String.Encoding.shiftJIS) else {
            handler(NSError(domain: "", code: 0, userInfo: nil))
            return
        }
        self.archive = tmp
//        entries = archive.extractOrderedContents()
//        NotificationCenter.default.addObserver(self, selector: #selector(didChangeUserDefaults(notification:)), name: UserDefaults.didChangeNotification, object: nil)
        
        print(archive)
        
        
        var directoryTable: [String: Node] = [:]
        
        let root =  Node(value: "/", entry: nil)
        directoryTable["/"] = root
        content.append(root)
        
        let entries = tmp.enumerated().sorted { (lhs, rhs) -> Bool in
            lhs.element.path < rhs.element.path
        }
        
        entries.forEach({
            print($0.element.path)
            
            if $0.element.type == .directory {
                if let directory = directoryTable[$0.element.path] {
                } else {
                    let a = $0.element.path as NSString
                    let directoryPath = a.deletingLastPathComponent + "/"
                    if let directory = directoryTable[directoryPath] {
                        let tmp = Node(value: ($0.element.path as NSString).lastPathComponent, entry: $0.element)
                        directory.children.append(tmp)
                        directoryTable[$0.element.path] = tmp
                    }
                }
            } else {
                let a = $0.element.path as NSString
                let directoryPath = a.deletingLastPathComponent + "/"
                print(a)
                print("directoryPath = " + directoryPath)
                if let directory = directoryTable[directoryPath] {
                    directory.children.append(Node(value: ($0.element.path as NSString).lastPathComponent, entry: $0.element))
                } else {
                    let parent = Node(value: directoryPath)
                    directoryTable[directoryPath] = parent
                    root.children.append(parent)
                    parent.children.append(Node(value: ($0.element.path as NSString).lastPathComponent, entry: $0.element))
                }
            }
//            self.content.append(Node(value: $0.element.path))
        })
        
        
        DispatchQueue.main.async {
            self.outlineView.expandItem(self.outlineView.item(atRow: 0), expandChildren: true)
        }
        handler(nil)
        
    }
}
    
