import XCTest
import UIKit
@testable import ListDiff
import Foundation

enum CollectionViewUpdaterResult {
    case exception(NSException)
    case success(visibleCellDataList: [CellData], expectedCellDataList: [CellData])
}

final class CollectionViewUpdater: NSObject, UICollectionViewDataSource {
    // MARK: - State
    private var cellData = [CellData]() // for UICollectionViewDataSource
    private var collectionView: UICollectionView?
    private var window: UIWindow?
    
    // MARK: - Internal
    func updateCollectionView(
        from: [CellData],
        to: [CellData],
        completion: @escaping (CollectionViewUpdaterResult) -> ())
    {
        let collectionView = makeAndReloadCollectionViewWith(cellData: from)
        
        let diff = List.diffing(
            oldArray: from,
            newArray: to
        ).forBatchUpdates() // If you remove `forBatchUpdates`, `ListDiffStressTests` will start to fail
        
        performBatchUpdates(
            of: collectionView,
            cellDataList: to,
            diff: diff,
            completion: completion
        )
    }
    
    func cleanUp() {
        cellData = []
        collectionView?.dataSource = nil
        collectionView?.removeFromSuperview()
        collectionView = nil
        window = nil
    }

    // MARK: - Private
    private func makeAndReloadCollectionViewWith(
        cellData: [CellData])
        -> UICollectionView
    {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.layer.speed = 100 // Speed up the animations
        self.window = window
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 1, height: 1) // To fit all cells in the screen 
        layout.minimumInteritemSpacing = 0.001
        layout.minimumLineSpacing = 0.001
        
        let collectionView = UICollectionView(frame: window.frame, collectionViewLayout: layout)
        self.collectionView = collectionView
        window.addSubview(collectionView)
        
        self.cellData = cellData
        collectionView.dataSource = self
        collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)
        collectionView.reloadData()
        
        return collectionView
    }
    
    private func performBatchUpdates(
        of collectionView: UICollectionView,
        cellDataList: [CellData],
        diff: List.Result,
        completion: @escaping (CollectionViewUpdaterResult) -> ())
    {
        var catchedException: NSException?
        
        ObjCExceptionCatcher.tryClosure(
            tryClosure: {
                tryPerformingBatchUpdates(
                    of: collectionView,
                    cellDataList: cellDataList,
                    diff: diff
                )
            },
            catchClosure: { exception in
                catchedException = exception
            },
            finallyClosure: {
                if let catchedException = catchedException {
                    completion(
                        .exception(catchedException)
                    )
                } else {
                    let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.row < $1.row }
                    
                    let visibleCellDataList: [CellData] = visibleIndexPaths.map {
                        let cell = collectionView.cellForItem(at: $0) as! Cell
                        return cell.cellData!
                    }
                    
                    completion(
                        .success(
                            visibleCellDataList: visibleCellDataList,
                            expectedCellDataList: cellDataList
                        )
                    )
                }
            }
        )
    }
    
    private func tryPerformingBatchUpdates(
        of collectionView: UICollectionView,
        cellDataList: [CellData],
        diff: List.Result)
    {
        collectionView.performBatchUpdates(
            _: {
                self.cellData = cellDataList
                
                // Deletes
                if !diff.deletes.isEmpty {
                    collectionView.deleteItems(
                        at: diff.deletes.map {
                            IndexPath(item: $0, section: 0)
                        }
                    )
                }
                
                // Inserts
                if !diff.inserts.isEmpty {
                    collectionView.insertItems(
                        at: diff.inserts.map {
                            IndexPath(item: $0, section: 0)
                        }
                    )
                }
                
                // Moves
                for move in diff.moves {
                    collectionView.moveItem(
                        at: IndexPath(item: move.from, section: 0),
                        to: IndexPath(item: move.to, section: 0)
                    )
                }
                
                if !diff.updates.isEmpty {
                    collectionView.reloadItems(
                        at: diff.updates.map {
                            IndexPath(item: $0, section: 0)
                        }
                    )
                }
            },
           completion: { _ in }
         )
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        cell.cellData = cellData[indexPath.row]
        return cell
    }
}
