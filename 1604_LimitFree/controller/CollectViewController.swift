//
//  CollectViewController.swift
//  1604_LimitFree
//
//  Created by gaokunpeng on 16/9/29.
//  Copyright © 2016年 apple. All rights reserved.
//

import UIKit

class CollectViewController: LFNavViewController {
    
    //数据源
    private var dataArray: NSMutableArray?
    
    //滚动视图
    private var scrollView: UIScrollView?
    
    //分页控件
    private var pageCtrl: UIPageControl?
    
    //是否删除状态
    private var isDelete = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //导航
        createMyNav()
        
        //创建滚动视图
        automaticallyAdjustsScrollViewInsets = false
        scrollView = UIScrollView(frame: CGRectMake(0,64,kScreenWidth,kScreenHeight-64))
        scrollView?.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        scrollView?.pagingEnabled = true
        view.addSubview(scrollView!)
        
        //分页控件
        pageCtrl = UIPageControl(frame: CGRectMake(80,kScreenHeight-60,200,20))
//        pageCtrl?.backgroundColor = UIColor.redColor()
        pageCtrl?.pageIndicatorTintColor = UIColor.blackColor()
        view.addSubview(pageCtrl!)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //查询数据
        let dbManager = LFDBManager()
        dbManager.searchAllCollectData {
            (array) in
            self.dataArray = NSMutableArray(array: array)
            
            //显示UI
            dispatch_async(dispatch_get_main_queue(), {
                self.showCollectData()
            })
        }
    }
    
    //显示收藏的数据
    func showCollectData(){
        
        //清空之前的子视图
        for tmpView in (scrollView?.subviews)! {
            if tmpView.isKindOfClass(CollectButton) {
                tmpView.removeFromSuperview()
            }
        }
        
        if dataArray?.count > 0 {
            let cnt = dataArray?.count
            
            let colNum = 3
            let btnW:CGFloat = 80 //按钮的宽度
            let btnH: CGFloat = 100 //按钮的高度
            let offsetX: CGFloat = 30 //第一列的x值
            let spaceX = (kScreenWidth-CGFloat(colNum) * btnW - offsetX * 2 - 20)/CGFloat(colNum-1)  //横向间距
            let offsetY: CGFloat = 120-64 //第一行的y值
            let spaceY: CGFloat = 80 //行间距
            for i in 0..<cnt! {
                
                //先计算页数
                let page = i/9
                
                //计算按钮的行和列
                let rowAndCol = i%9
                let row = rowAndCol/colNum
                let col = rowAndCol%colNum
                
                let btnX = offsetX + CGFloat(col) * (btnW + spaceX) + CGFloat(page)*kScreenWidth
                let btnY = offsetY + CGFloat(row) * (btnH + spaceY)
                let btn = CollectButton(frame: CGRectMake(btnX,btnY,btnW,btnH))
                //显示数据
                btn.model = dataArray![i] as? CollectModel
                //设置删除状态
                btn.isDelete = isDelete
                
                scrollView!.addSubview(btn)
                //添加点击事件
                btn.addTarget(self, action: #selector(clickBtn(_:)), forControlEvents: .TouchUpInside)
                //闭包
                btn.deleteClosure = {
                    index in
                    //1.从数据库删除
                    let model = self.dataArray![index] as! CollectModel
                    
                    let dbManager = LFDBManager()
                    dbManager.deleteWithAppId(model.applicationId!) {
                        (flag) in
                        if flag == true {
                            //2.从数据源数组删除
                            self.dataArray?.removeObjectAtIndex(index)
                            //3.重新显示
                            self.showCollectData()
                            
                        }else{
                            MyUtil.showAlertMsg("删除失败", onViewController: self)
                        }
                    }
                    

                }
                //序号
                btn.btnIndex = i
                
            }
            
            //设置滚动范围
            var pageCnt = cnt! / 9
            if cnt! % 9 > 0 {
                pageCnt += 1
            }
            scrollView?.contentSize = CGSizeMake(CGFloat(pageCnt)*kScreenWidth, 0)
            //设置代理
            scrollView?.delegate = self
            
            //设置分页控件
            pageCtrl?.numberOfPages = pageCnt
            pageCtrl?.currentPage = 0
            
            
        }else{
            //没有收藏
            MyUtil.showAlertMsg("还没有任何收藏的数据", onViewController: self)
        }
        
    }
    
    func clickBtn(btn: CollectButton)  {
        
        if isDelete == false {
            //点击进入详情界面
            let detailCtrl = DetailViewController()
            detailCtrl.appId = btn.model?.applicationId
            navigationController?.pushViewController(detailCtrl, animated: true)
        }
        
    }
    
    //导航
    func createMyNav() {
        //返回
        addBackButton()
        //标题
        addNavTitle("我的收藏")
        //编辑
        addNavButton("编辑", target: self, action: #selector(editAction(_:)), isLeft: false)
    }
    
    //编辑
    func editAction(btn: UIButton){
        
        if isDelete == false {
            //进入删除状态
            
            //1.修改文字
            btn.setTitle("完成", forState: .Normal)
            //2.显示删除按钮
            for tmpView in (scrollView?.subviews)! {
                if tmpView.isKindOfClass(CollectButton) {
                    let btn = tmpView as! CollectButton
                    btn.isDelete = true
                }
            }
            //3.修改属性
            isDelete = true
            
        }else{
            //退出删除状态，回到正常状态
            
            //1.修改文字
            btn.setTitle("编辑", forState: .Normal)
            //2.显示删除按钮
            for tmpView in (scrollView?.subviews)! {
                if tmpView.isKindOfClass(CollectButton) {
                    let btn = tmpView as! CollectButton
                    btn.isDelete = false
                }
            }
            //3.修改属性
            isDelete = false
            
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


//MARK: UIScrollView代理
extension CollectViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
        pageCtrl?.currentPage = index
    }
    
}




