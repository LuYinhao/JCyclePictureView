//
//  JCyclePictureView.swift
//  JCyclePictureView
//
//  Created by Zebra on 2017/12/15.
//  Copyright © 2017年 Zebra. All rights reserved.
//

import UIKit
import Kingfisher

private let JCyclePictureCellIdentifier: String = "JCyclePictureViewCell"

typealias JCyclePictureViewCustomCellHandle = (_ collectionView: UICollectionView, _ indexPath: IndexPath, _ picture: String) -> UICollectionViewCell

/// 滚动方向
enum JCyclePictureViewRollingDirection : Int {
    
    case top
    
    case left
    
    case bottom
    
    case right
}

/// PageControl 的位置
enum JPageControlStyle : Int {
    
    case center
    
    case left
    
    case right
}

class JCyclePictureView: UIView {

    /// 图片数据源
    var pictures: [String] = []
    
    /// 默认图
    var placeholderImage: UIImage?
    
    /// 标题数据源
    var titles: [String?] = [] {
        
        willSet {
            
            if newValue.count > 0 {
                
                self.pageControlStyle = .right
                
                self.titleLab.text = newValue.count > self.index ? newValue[self.index] : ""
                
                self.bringSubview(toFront: self.pageControl)
            }
        }
    }
    
    /// 点击图片回调  从 0 开始
    var didTapAtIndexHandle: (( _: Int ) -> Void)?
    
    /// default is 2.0f, 如果小于0.5不自动播放
    var autoScrollDelay: TimeInterval = 2
    
    /// 滚动方向
    var direction: JCyclePictureViewRollingDirection = .left {
        
        willSet {
            
            switch newValue {
            case .left, .top:
                self.pageControl.currentPage = 0
                self.index = 0
                
            case .right, .bottom:
                self.pageControl.currentPage = self.pictures.count - 1
                self.index = self.pictures.count - 1
            }
        }
    }
    
    /// pageControl 的对齐方式
    var pageControlStyle: JPageControlStyle = .center {
        
        willSet {
            
            guard self.titles.count == 0 else { return }
            
            let pointSize: CGSize = self.pageControl.size(forNumberOfPages: self.pictures.count)
            
            let page_x: CGFloat = (self.pageControl.bounds.size.width - pointSize.width) / 2
            
            switch newValue {
            case .left:
                self.pageControl.frame = CGRect(x: -page_x + 10, y: self.frame.size.height - 20, width: self.pageControl.bounds.size.width, height: self.pageControl.bounds.size.height)
                
            case .right:
                self.pageControl.frame = CGRect(x: page_x - 10, y: self.frame.size.height - 20, width: self.pageControl.bounds.size.width, height: self.pageControl.bounds.size.height)
                
            case .center:
                self.pageControl.frame = CGRect(x: 0, y: self.frame.size.height - 20, width: self.pageControl.bounds.size.width, height: self.pageControl.bounds.size.height)
            }
        }
    }
    
    /// 设置图片的ContentMode
    var imageContentMode: UIViewContentMode?
    
    /// 自定义 cell 的回调
    private var customCellHandle: JCyclePictureViewCustomCellHandle?
    
    /// 如果需要自定义 AnyClass cell 需调用下面方法
    ///
    /// - Parameters:
    ///   - cellClasss: [UICollectionViewCell.self]
    ///   - identifiers: [identifier]
    ///   - customCellHandle: cellForItemAt 回调
    func register(_ cellClasss: [Swift.AnyClass?], identifiers: [String], customCellHandle: @escaping JCyclePictureViewCustomCellHandle) {
        
        self.customCellHandle = customCellHandle

        for (index, identifier) in identifiers.enumerated() {
            
            self.collectionView.register(cellClasss[index], forCellWithReuseIdentifier: identifier)
        }
    }
    
    /// 如果需要自定义 UINib cell 需调用下面方法
    ///
    /// - Parameters:
    ///   - nibs: [UINib]
    ///   - identifiers: [identifier]
    ///   - customCellHandle: cellForItemAt 回调
    func register(_ nibs: [UINib?], identifiers: [String], customCellHandle: @escaping JCyclePictureViewCustomCellHandle) {
        
        self.customCellHandle = customCellHandle
        
        for (index, identifier) in identifiers.enumerated() {
            
            self.collectionView.register(nibs[index], forCellWithReuseIdentifier: identifier)
        }
    }
    
    private var timer: Timer?
    
    lazy private var titleBgView: UIView = {
        
        let titleBgView: UIView = UIView(frame: CGRect(x: 0, y: self.frame.height - 20, width: self.frame.width, height: 20))
        
        titleBgView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        self.addSubview(titleBgView)
        
        return titleBgView
    }()
    
    lazy var titleLab: UILabel = {
        
        let pointSize: CGSize = self.pageControl.size(forNumberOfPages: self.pictures.count)
        
        let titleLab: UILabel = UILabel(frame: CGRect(x: 5, y: 0, width: self.frame.width - 10 - pointSize.width, height: 20))
        
        titleLab.textColor = UIColor.white
        
        titleLab.font = UIFont.systemFont(ofSize: 13)
        
        self.titleBgView.addSubview(titleLab)
        
        return titleLab
    }()
    
    private var datas: [String]? {
        
        var firstIndex = 0
        
        var secondIndex = 0

        var thirdIndex = 0

        switch pictures.count {
            
        case 0:
            return []
            
        case 1:
            break
            
        default:
            firstIndex = (self.index - 1) < 0 ? pictures.count - 1 : self.index - 1
            secondIndex = self.index
            thirdIndex = (self.index + 1) > pictures.count - 1 ? 0 : self.index + 1
        }
        
        return [pictures[firstIndex] ,pictures[secondIndex] ,pictures[thirdIndex]]
    }
    
    private var index: Int = 0 {
        
        willSet {
            
            if self.titles.count > 0 {
                
                self.titleLab.text = self.titles.count > newValue ? self.titles[newValue] : ""
            }
        }
    }
    
    private lazy var contentOffset: CGFloat = {
        
        switch self.direction {
        case .left, .right:
            return  self.collectionView.contentOffset.x
            
        case .top, .bottom:
            return  self.collectionView.contentOffset.y
        }
    }()
    
    private lazy var scrollPosition: UICollectionViewScrollPosition = {
        
        switch self.direction {
        case .left:
            return UICollectionViewScrollPosition.left
            
        case .right:
            return UICollectionViewScrollPosition.right
            
        case .top:
            return UICollectionViewScrollPosition.top
            
        case .bottom:
            return  UICollectionViewScrollPosition.bottom
        }
    }()
    
    /// PageControl
    lazy var pageControl: JPageControl = {
        
        let pageControl: JPageControl = JPageControl(frame: CGRect(x: 0, y: self.frame.size.height - 20, width: self.frame.size.width, height: 20))
        
        pageControl.numberOfPages = self.pictures.count
        
        pageControl.backgroundColor = UIColor.clear
        
        pageControl.currentPage = 0
        
        self.addSubview(pageControl)
        
        return pageControl
    }()
    
    private lazy var collectionView: UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        layout.itemSize = frame.size
        
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        layout.minimumLineSpacing = 0
        
        layout.minimumInteritemSpacing = 0
        
        switch self.direction {
        case .left, .right:
            layout.scrollDirection = .horizontal
            
        case .top, .bottom:
            layout.scrollDirection = .vertical
        }
        
        let collectionView: UICollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), collectionViewLayout: layout)
        
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(JCyclePictureViewCell.self, forCellWithReuseIdentifier: JCyclePictureCellIdentifier)
        
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.isPagingEnabled = true
        
        collectionView.bounces = false
        
        collectionView.dataSource = self
        
        collectionView.delegate = self
        
        self.addSubview(collectionView)
        
        return collectionView
    }()
    
    convenience init(frame: CGRect, pictures: [String]?) {
        
        self.init(frame: frame)
        
        if let pictures = pictures {
        
            self.pictures = pictures
        }
        
        self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: self.scrollPosition, animated: false)
        
        self.bringSubview(toFront: self.pageControl)
        
        self.startTimer()
    }
    
    deinit {
        
        self.stopTimer()
    }
    
}

extension JCyclePictureView: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        self.stopTimer()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        self.startTimer()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        var offset: CGFloat = 0
        
        switch self.direction {
        case .left, .right:
            offset = scrollView.contentOffset.x
            
        case .top, .bottom:
            offset = scrollView.contentOffset.y
        }
        
        if offset >= self.contentOffset * 2 {
            
            if self.index == self.pictures.count - 1 {
                
                self.index = 0
                
            } else {
                
                self.index += 1
            }
            
            self.collectionView.reloadData()

            self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: self.scrollPosition, animated: false)
        }
        
        if offset <= 0 {
            
            if self.index == 0 {
                
                self.index = self.pictures.count - 1
                
            } else {
                
                self.index -= 1
            }
            
            self.collectionView.reloadData()

            self.collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: self.scrollPosition, animated: false)
        }
        
        UIView.animate(withDuration: 0.3) {
            
            self.pageControl.currentPage = self.index
        }
    }
    
    /// 添加定时器
    private func startTimer() {
        
        self.stopTimer()
        
        if self.autoScrollDelay >= 0.5 {
            
            self.timer = Timer.scheduledTimer(timeInterval: self.autoScrollDelay, target: self, selector: #selector(timerHandle), userInfo: nil, repeats: true)
            
            RunLoop.main.add(self.timer!, forMode: .commonModes)
        }
    }
    
    //关闭定时器
    private func stopTimer() {
        
        if let _ = timer?.isValid {
            
            timer?.invalidate()
            
            timer = nil
        }
    }
    
    @objc private func timerHandle() {
        
        var item: Int = 0
        
        switch self.direction {
        case .left, .bottom:
            item = 2
            
        case .top, .right:
            item = 0
        }
        
        self.collectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: self.scrollPosition, animated: true)
    }
}

//MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension JCyclePictureView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let customCellHandle = self.customCellHandle {
            
            return customCellHandle(collectionView, indexPath, self.datas![indexPath.item])
            
        } else {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JCyclePictureCellIdentifier, for: indexPath) as! JCyclePictureViewCell

            if let imageContentMode = self.imageContentMode {
                
                cell.imageView.contentMode = imageContentMode
            }
            
            if self.datas![indexPath.item].hasPrefix("http") {
                
                cell.imageView.kf.setImage(with: URL(string: self.datas![indexPath.item]), placeholder: self.placeholderImage)
                
            } else {
                
                cell.imageView.image = UIImage(named: self.datas![indexPath.item])
            }
            
            return cell
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.didTapAtIndexHandle?(indexPath.item)
    }
}

internal class JPageControl: UIPageControl {
    
    /// 设置高亮显示图片
    var currentPageIndicatorImage: UIImage? {
        
        didSet {
            
             self.currentPageIndicatorTintColor = UIColor.clear
        }
    }
    
    /// 设置默认显示图片
    var pageIndicatorImage: UIImage? {
        
        didSet {
            
            self.pageIndicatorTintColor = UIColor.clear
        }
    }
    
    override var currentPage: Int {
        
        willSet {
            
            self.updateDots()
        }
    }
    
    func updateDots() {
        
        if self.currentPageIndicatorImage != nil || self.pageIndicatorImage != nil {
            
            for (index, dot) in self.subviews.enumerated() {
                
                if dot.subviews.count == 0 {
                    
                    let imageView: UIImageView = UIImageView()
                    
                    imageView.frame = dot.bounds

                    dot.addSubview(imageView)
                }
                    
                if let imageView = dot.subviews[0] as? UIImageView {

                    imageView.image = self.currentPage == index ? self.currentPageIndicatorImage ?? UIImage() : self.pageIndicatorImage ?? UIImage()
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class JCyclePictureViewCell: UICollectionViewCell {
    
    let imageView: UIImageView = UIImageView()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}