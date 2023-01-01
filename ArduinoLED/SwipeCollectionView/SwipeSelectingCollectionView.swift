//
//  SwipeSelectingCollectionView.swift
//  SwipeSelectingCollectionView
//
//  Adapted from Shane Qi on 7/2/17.
//  Copyright © 2017 Shane Qi. All rights reserved.
//

import UIKit

public class SwipeSelectingCollectionView: UICollectionView {

    private var lastIndexPath: IndexPath?
    //private var selectingRange: ClosedRange<IndexPath>?
    //private var selectingMode: SelectingMode = .selecting
    //private var selectingIndexPaths = Set<IndexPath>()

//    private enum SelectingMode {
//        case selecting, deselecting
//    }

    lazy private var panSelectingGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = SwipeSelectingGestureRecognizer(
            target: self,
            action: #selector(SwipeSelectingCollectionView.didPanSelectingGestureRecognizerChange(gestureRecognizer:)))
        return gestureRecognizer
    } ()

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        gestureRecognizers?.append(panSelectingGestureRecognizer)
        allowsMultipleSelection = true
    }

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        gestureRecognizers?.append(panSelectingGestureRecognizer)
        allowsMultipleSelection = true
    }

    @objc private func didPanSelectingGestureRecognizerChange(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        switch gestureRecognizer.state {
        case .began:
            self.lastIndexPath = indexPathForItem(at: point)
            if let indexPath = lastIndexPath {
                let newIndexPath = IndexPath(item: indexPath.item, section: -2)
                setSelection(true, indexPath: newIndexPath)
            }
        case .changed:
            handleChangeOf(gestureRecognizer: gestureRecognizer)
        case .ended:
            lastIndexPath = nil
            NotificationCenter.default.post(name: .didFinishSwipe, object: nil)
        default:
            lastIndexPath = nil
        }
    }

    private func handleChangeOf(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        if let indexPath: IndexPath = self.indexPathForItem(at: point) {
            if indexPath != lastIndexPath {
                let newIndexPath = IndexPath(item: indexPath.item, section: -1)
                setSelection(true, indexPath: newIndexPath)
                lastIndexPath = indexPath
            }
        }
    }

    private func setSelection(_ selected: Bool, indexPath: IndexPath) {
        switch selected {
        case true:
            if delegate?.collectionView?(self, shouldSelectItemAt: indexPath) ?? true {
                delegate?.collectionView?(self, didSelectItemAt: indexPath)
                selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        case false:
            delegate?.collectionView?(self, didDeselectItemAt: indexPath)
            deselectItem(at: indexPath, animated: false)
        }
    }

}
