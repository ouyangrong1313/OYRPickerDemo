//
//  MLPickerScrollView.m
//  MLPickerScrollView
//
//  Created by MelodyLuo on 15/8/14.
//  Copyright (c) 2015年 MelodyLuo. All rights reserved.
//

#define kAnimationTime .2

#import "MLPickerScrollView.h"
#import "MLPickerItem.h"

@interface MLPickerScrollView ()<UIScrollViewDelegate>

@property (nonatomic,strong)UIScrollView *scrollView;
@property (nonatomic,strong)NSMutableArray *items;

@end

@implementation MLPickerScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUp];
    }
    return self;
}

#pragma mark - UI
- (void)setUp
{
    self.items = [NSMutableArray array];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:
                       CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.decelerationRate = 0.5;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.firstItemX = 0;
    [self addSubview:self.scrollView];
}

#pragma mark - layout Items
- (void)layoutSubviews
{
    
    NSLog(@"   ---  layoutSubviews   --- ");
    
    [super layoutSubviews];
    
    if (!self.items) {
        return;
    }
    
    [self layoutItems];
}

- (void)layoutItems
{
    
    NSLog(@"  ---  刷新数据后重新布局  ---  ");
    
    // layout
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    // item起始X值
    CGFloat startX = self.firstItemX;
    
    NSLog(@"  CGRectGetHeight(self.bounds) : %f   self.itemHeight : %f",CGRectGetHeight(self.bounds),self.itemHeight);
    
    for (int i = 0; i < self.items.count; i++) {
        MLPickerItem *item = [self.items objectAtIndex:i];
        item.frame = CGRectMake(startX, CGRectGetHeight(self.bounds)-self.itemHeight, self.itemWidth, self.itemHeight);
        startX += self.itemWidth;//记录x的坐标
    }
    // startX的坐标(所有itemWidth的和) + scrollview.width + firstItemX (0) - itemWidth * 0.5
    self.scrollView.contentSize = CGSizeMake(MAX(startX+CGRectGetWidth(self.bounds)-self.firstItemX-self.itemWidth *.5, startX), CGRectGetHeight(self.bounds));
    //计算滚动区间
    [self setItemAtContentOffset:self.scrollView.contentOffset];
    NSLog(@" self.scrollView.contentOffset.width: %f  self.scrollView.contentOffset.height: %f  self.scrollView.contentOffset.x: %f",self.scrollView.contentSize.width,self.scrollView.contentSize.height,self.scrollView.contentOffset.x);

    /* 
     self.scrollView.contentOffset.width: 869.400000  
     self.scrollView.contentOffset.height: 110.000000  
     self.scrollView.contentOffset.x: 0.000000
     */
    
    
    
}

#pragma mark - public Method（GetData）
- (void)reloadData
{
    // remove
    for (MLPickerItem *item in self.items) {
        [item removeFromSuperview];
    }
    [self.items removeAllObjects];
    
    // create
    NSInteger count = 0;
    if ([self.dataSource respondsToSelector:@selector(numberOfItemAtPickerScrollView:)]) {
        count = [self.dataSource numberOfItemAtPickerScrollView:self];
    }//刷新界面的时候获取items的个数
    
    for (NSInteger i = 0; i < count; i++) {//获取到items的个数后再获取到每个items的实例对象
        MLPickerItem *item = nil;
        if ([self.dataSource respondsToSelector:@selector(pickerScrollView:itemAtIndex:)]) {
            item = [self.dataSource pickerScrollView:self itemAtIndex:i];
        }
        //把每个item添加到scrollview
        NSAssert(item, @"[self.dataSource pickerScrollView: itemAtIndex:index] can not nil");
        item.originalSize = CGSizeMake(self.itemWidth, self.itemHeight);
        [self.items addObject:item];
        [self.scrollView addSubview:item];
        item.index = i;//选中回调index
    }
    
    // layout
    [self layoutItems];
}

- (void)scollToSelectdIndex:(NSInteger)index
{
    [self selectItemAtIndex:index];
}

#pragma mark - Helper
/* 根据scrollView的contentoffset来 是哪个item处于中心点区域， 然后传出去通知外面 */
- (void)setItemAtContentOffset:(CGPoint)offset
{
    NSInteger centerIndex = roundf(offset.x / self.itemWidth);//返回最接近_X的整数
    
    NSLog(@" setItemAtContentOffset： %ld  移动距离offset——x： %f",(long)centerIndex,offset.x);
    
    for (int i = 0; i < self.items.count; i++) {
        MLPickerItem * item = [self.items objectAtIndex:i];
        [self itemInCenterBack:item];
        if (centerIndex == i) {
            [self itemInCenterChange:item];
            _seletedIndex = centerIndex;
        }
    }
}

- (void)scollToItemViewAtIndex:(NSInteger)index animated:(BOOL)animated
{
    CGPoint point = CGPointMake(index * _itemWidth,self.scrollView.contentOffset.y);
    NSLog(@"  ---  scollToItemViewAtIndex  --- index: %ld  point: %f",index,point.x);
    [UIView animateWithDuration:kAnimationTime animations:^{
        [self.scrollView setContentOffset:point];
    } completion:^(BOOL finished) {
        [self setItemAtContentOffset:point];
    }];
    //先移动再让中间的变大
}
//滑动停止的时候调用这个方法
/*
 contentSize:scrollview可显示的区域
 属性类型：
 struct CGSize {
 CGFloat width;
 CGFloat height;
 };
 typedef struct CGSize CGSize;
 
 contentOffset:scrollview当前显示区域顶点相对于frame顶点的偏移量
 属性类型：
 struct CGPoint {
 CGFloat x;
 CGFloat y;
 };
 typedef struct CGPoint CGPoint;
 
 contentInset:scrollview的contentview的顶点相对于scrollview的位置
 属性类型：
 typedef struct UIEdgeInsets {
 CGFloat top, left, bottom, right;
 } UIEdgeInsets;
 
 */

- (void)setCenterContentOffset:(UIScrollView *)scrollView
{
    
    CGFloat offsetX = scrollView.contentOffset.x;//移动的x距离
    NSLog(@" scrollView offsetX : %f",offsetX);
    if (offsetX < 0) {
        offsetX = self.itemWidth * 0.5;//offsetX 为负的时候就滑到第一个位置
    }else if (offsetX > (self.items.count - 1) * self.itemWidth) {
        offsetX = (self.items.count - 1) * self.itemWidth;
    }
    
    NSInteger value = roundf(offsetX / self.itemWidth);//滑到第几个
    
    NSLog(@" value : %ld  offsetX : %f",value,offsetX);
    
    [UIView animateWithDuration:kAnimationTime animations:^{
        [scrollView setContentOffset:CGPointMake(self.itemWidth * value, scrollView.contentOffset.y)];//滑动到哪个就移动到哪个
    } completion:^(BOOL finished) {
        [self setItemAtContentOffset:scrollView.contentOffset];//然后使中间的最大
    }];
}

#pragma mark - delegate
- (void)selectItemAtIndex:(NSInteger)index
{
    NSLog(@"点击选中index ： %ld",index);
    _seletedIndex = index;
    [self scollToItemViewAtIndex:_seletedIndex animated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerScrollView:didSelecteItemAtIndex:)]) {
        [self.delegate pickerScrollView:self didSelecteItemAtIndex:_seletedIndex];
    }
}

- (void)itemInCenterChange:(MLPickerItem*)item
{
    if ([self.delegate respondsToSelector:@selector(itemForIndexChange:)]) {
        [self.delegate itemForIndexChange:item];
    }
}

- (void)itemInCenterBack:(MLPickerItem*)item
{
    if ([self.delegate respondsToSelector:@selector(itemForIndexBack:)]) {
        [self.delegate itemForIndexBack:item];
    }
}

#pragma mark - scrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //NSLog(@"  --  scrollViewDidScroll   --   ");
    for (int i = 0; i < self.items.count; i++) {
        MLPickerItem * item = [self.items objectAtIndex:i];
        [self itemInCenterBack:item];
    }
}

/** 手指离开屏幕后ScrollView还会继续滚动一段时间直到停止 时执行
 *  如果需要scrollview在停止滑动后一定要执行某段代码的话应该搭配scrollViewDidEndDragging函数使用
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"  --  scrollViewDidEndDecelerating   --   ");

    [self setCenterContentOffset:scrollView];
}

/** UIScrollView真正停止滑动，应该怎么判断: 当decelerate = true时，才会调UIScrollView的delegate */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        NSLog(@"  --  scrollViewDidEndDragging   --   ");
        [self setCenterContentOffset:scrollView];
    }
}

@end
