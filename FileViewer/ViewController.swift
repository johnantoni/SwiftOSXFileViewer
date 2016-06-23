/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Cocoa

class ViewController: NSViewController {
  
  @IBOutlet weak var statusLabel:NSTextField!
  @IBOutlet weak var tableView: NSTableView!
  
  let sizeFormatter = NSByteCountFormatter()
  var directory:Directory?
  var directoryItems:[Metadata]?
  var sortOrder = Directory.FileOrder.Name
  var sortAscending = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    statusLabel.stringValue = ""
    tableView.setDelegate(self)
    tableView.setDataSource(self)
    tableView.target = self
    tableView.doubleAction = "tableViewDoubleClick:"
    //1.
    let descriptorName = NSSortDescriptor(key: Directory.FileOrder.Name.rawValue, ascending: true)
    let descriptorDate = NSSortDescriptor(key: Directory.FileOrder.Date.rawValue, ascending: true)
    let descriptorSize = NSSortDescriptor(key: Directory.FileOrder.Size.rawValue, ascending: true)
    //2.
    tableView.tableColumns[0].sortDescriptorPrototype = descriptorName;
    tableView.tableColumns[1].sortDescriptorPrototype = descriptorDate;
    tableView.tableColumns[2].sortDescriptorPrototype = descriptorSize;
  }
  
  override var representedObject: AnyObject? {
    didSet {
      if let url = representedObject as? NSURL {
        directory = Directory(folderURL: url)
        reloadFileList()
        
      }
    }
  }
  func tableViewDoubleClick( sender:AnyObject ) {
    
    //1.
    guard tableView.selectedRow >= 0 , let item = directoryItems?[tableView.selectedRow] else {
      return
    }
    
    if item.isFolder {
      //2.
      self.representedObject = item.url
    }
    else {
      //3.
      NSWorkspace.sharedWorkspace().openURL(item.url)
    }
  }
  
  func updateStatus() {
    
    let text:String
    // 1
    let itemsSelected = tableView.selectedRowIndexes.count
    
    // 2
    if ( directoryItems == nil ) {
      text = ""
    }
    else if( itemsSelected == 0 ) {
      text =   "\(directoryItems!.count) items"
    }
    else
    {
      text = "\(itemsSelected) of \(directoryItems!.count) selected"
    }
    // 3
    statusLabel.stringValue = text
  }
  
  func reloadFileList() {
    directoryItems = directory?.contentsOrderedBy(sortOrder, ascending: sortAscending)
    tableView.reloadData()
  }
}

extension ViewController : NSTableViewDataSource {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return directoryItems?.count ?? 0
  }
  
  func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    //1
    guard let sortDescriptor = tableView.sortDescriptors.first else {
      return
    }
    if let order = Directory.FileOrder(rawValue: sortDescriptor.key! ) {
      //2.
      sortOrder = order
      sortAscending = sortDescriptor.ascending
      reloadFileList()
    }
  }
  
}

extension ViewController : NSTableViewDelegate {
  
  func tableViewSelectionDidChange(notification: NSNotification) {
    updateStatus()
  }
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
    var image:NSImage?
    var text:String=""
    var cellIdentifier:String=""
    
    // 1
    guard let item = directoryItems?[row] else {
      return nil
    }
    
    // 2
    if tableColumn == tableView.tableColumns[0] {
      image = item.icon
      text = item.name
      cellIdentifier = "NameCellID"
    }
    else if tableColumn == tableView.tableColumns[1] {
      text = item.date.description
      cellIdentifier = "DateCellID"
    }
    else if tableColumn == tableView.tableColumns[2] {
      text = item.isFolder ? "--" : sizeFormatter.stringFromByteCount(item.size)
      cellIdentifier = "SizeCellID"
    }
    
    // 3
    if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil ) as? NSTableCellView {
      cell.textField?.stringValue = text
      cell.imageView?.image = image ?? nil
      return cell
    }
    return nil
  }
}