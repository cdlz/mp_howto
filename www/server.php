<?php
include __DIR__ . '/vendor/autoload.php'; // 引入 composer 入口文件
use EasyWeChat\Foundation\Application;
use EasyWeChat\Support\Log;
use EasyWeChat\Message\Text;
$options = [
    'debug'  => true,
    'app_id' => 'wx_appid',
    'secret' => 'key',
    'token'  => 'token',
    'aes_key' => 'aes_key', // 可选
    'log' => [
        'level' => 'debug',
        'file'  => '/tmp/easywechat.log', // XXX: 绝对路径！！！！
    ],
    //...
];
$app = new Application($options);
// 从项目实例中得到服务端应用实例。
$server = $app->server;

$server->setMessageHandler(function ($message) {
    switch ($message->MsgType) {
        case 'event':
            # 事件消息...
            break;
        case 'text':
            # 文字消息...
            break;
        case 'image':
            # 图片消息...
            break;
        case 'voice':
            # 语音消息...
            break;
        case 'video':
            # 视频消息...
            break;
        case 'location':
            # 坐标消息...
            break;
        case 'link':
            # 链接消息...
            break;
        // ... 其它消息
        default:
            # code...
            break;
    }
    // ...
    $ret = "welcome to here,".$message->FromUserName ;
	Log::debug("=================".$ret);
    return new Text(['content' => $ret ]);
});
$response = $server->serve();
Log::debug("in...");
//$message = $server->getMessage();

// 将响应输出
$response->send(); // Laravel 里请使用：return $response;


?>

