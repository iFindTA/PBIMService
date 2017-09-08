私有库有引用私有库的情况，在验证已经推送podspec的时候都需要加上所有的资源地址，不然，pod会默认从cocoapods官方查询的。
如，私有库a要引用私有库b，在验证与推送私有库a的时候，要加上私有库b的远程仓库地址，如下

　　注意：要在pod lib lint 或者 pod spec lint 以及 pod repo push ....时候加上被引用的私有库地址
pod spec lint --sources='#私有库b的远程仓库地址(如：http://xxxxxx.git)#,https://github.com/CocoaPods/Specs'
　pod repo push #本地Repo名字# #.podspec名# --sources='[私有库b的远程仓库地址(如：http://xxxxxx.git)],https://github.com/CocoaPods/Specs'

eg：
　pod spec lint --sources='http://xxxxxx/iOSRepos.git,https://github.com/CocoaPods/Specs'

　pod repo push iOSTest iOSTest.podspec --sources='http://git.yinqiyun.com/xfx/iOSRepos.git,https://github.com/CocoaPods/Specs'

有多少个私有库就加多少个地址，用 半角“,”隔开。
这里的私有库地址：http://192.168.10.99/iOSKits/Specs.git, 官方为：https://github.com/CocoaPods/Specs
pod lib lint --sources='http://192.168.10.99/iOSKits/Specs.git,https://github.com/CocoaPods/Specs' --allow-warnings --verbose

pod repo push FLKSpecs FLKNetService.podspec --sources='http://192.168.10.99/iOSKits/Specs.git,https://github.com/CocoaPods/Specs' --allow-warnings --verbose