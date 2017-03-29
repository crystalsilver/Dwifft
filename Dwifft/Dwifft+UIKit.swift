//
//  TableViewDiffCalculator.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/13/15.
//  Copyright (c) 2015 Places. All rights reserved.
//

#if os(iOS)

import UIKit

public protocol DiffCalculator: class {
    associatedtype S: Equatable
    associatedtype T: Equatable
    var rowsAndSections: SectionedValues<S, T> { get set }
    func numberOfSections() -> Int
    func value(forSection: Int) -> S
    func numberOfObjects(inSection section: Int) -> Int
    func value(atIndexPath indexPath: IndexPath) -> T
}

public extension DiffCalculator {
    public func numberOfSections() -> Int {
        return self.rowsAndSections.count
    }

    public func value(forSection: Int) -> S {
        return self.rowsAndSections[forSection].0
    }

    public func numberOfObjects(inSection section: Int) -> Int {
        return self.rowsAndSections[section].1.count
    }

    public func value(atIndexPath indexPath: IndexPath) -> T {
        return self.rowsAndSections[indexPath.section].1[indexPath.row]
    }
}

public class TableViewDiffCalculator<S: Equatable, T: Equatable>: DiffCalculator {

    public weak var tableView: UITableView?

    public init(tableView: UITableView, initialRowsAndSections: SectionedValues<S, T> = SectionedValues()) {
        self.tableView = tableView
        self._rowsAndSections = initialRowsAndSections
    }

    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.automatic, deletionAnimation = UITableViewRowAnimation.automatic

    /// Change this value to trigger animations on the table view.
    private var _rowsAndSections: SectionedValues<S, T>
    public var rowsAndSections : SectionedValues<S, T> {
        get {
            return _rowsAndSections
        }
        set {
            let oldRowsAndSections = rowsAndSections
            let newRowsAndSections = newValue
            let diff = Diff2D(lhs: oldRowsAndSections, rhs: newRowsAndSections)
            if (diff.results.count > 0) {
                tableView?.beginUpdates()
                self._rowsAndSections = newValue
                for result in diff.results {
                    switch result {
                    case .sectionInsert(let sectionIndex, _):
                        self.tableView?.insertSections(IndexSet(integer: sectionIndex), with: self.insertionAnimation)
                    case .sectionDelete(let sectionIndex, _):
                        self.tableView?.deleteSections(IndexSet(integer: sectionIndex), with: self.deletionAnimation)
                    case .insert(let sectionIndex, let rowIndex, _):
                        self.tableView?.insertRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: self.insertionAnimation)
                    case .delete(let sectionIndex, let rowIndex, _):
                        self.tableView?.deleteRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: self.deletionAnimation)
                    }
                }
                tableView?.endUpdates()
            }
        }
    }

}

public class CollectionViewDiffCalculator<S: Equatable, T: Equatable> : DiffCalculator {

    public weak var collectionView: UICollectionView?

    public init(collectionView: UICollectionView, initialRowsAndSections: SectionedValues<S, T> = SectionedValues()) {
        self.collectionView = collectionView
        _rowsAndSections = initialRowsAndSections
    }

    // Since UICollectionView (unlike UITableView) takes a block which must update its data source and trigger animations, we need to trigger the changes on set, instead of explicitly before and after set. This backing array lets us use a getter/setter in the exposed property.
    private var _rowsAndSections: SectionedValues<S, T>

    /// Change this value to trigger animations on the collection view.
    public var rowsAndSections : SectionedValues<S, T> {
        get {
            return _rowsAndSections
        }
        set {
            let oldRowsAndSections = rowsAndSections
            let newRowsAndSections = newValue
            let diff = Diff2D(lhs: oldRowsAndSections, rhs: newRowsAndSections)
            if (diff.results.count > 0) {
                collectionView?.performBatchUpdates({ () -> Void in
                    self._rowsAndSections = newValue

                    for result in diff.results {
                        switch result {
                        case .sectionInsert(let sectionIndex, _):
                            self.collectionView?.insertSections(IndexSet(integer: sectionIndex))
                        case .sectionDelete(let sectionIndex, _):
                            self.collectionView?.deleteSections(IndexSet(integer: sectionIndex))
                        case .insert(let sectionIndex, let rowIndex, _):
                            self.collectionView?.insertItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
                        case .delete(let sectionIndex, let rowIndex, _):
                            self.collectionView?.deleteItems(at: [IndexPath(row: rowIndex, section: sectionIndex)])
                        }
                    }
                }, completion: nil)
            }
            
        }
    }

}

#endif
