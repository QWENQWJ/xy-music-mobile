/*
 * @Description: 服务注册发现
 * @Author: chenzedeng
 * @Date: 2021-06-14 13:00:03
 * @LastEditTime: 2021-06-16 22:27:42
 */
import 'package:xy_music_mobile/config/service_manage.dart';
import 'package:xy_music_mobile/service/kg_music_service.dart';
import 'package:xy_music_mobile/service/mg_music_servce.dart';
import 'package:xy_music_mobile/service/ranking/kg_ranking_service.dart';
import 'package:xy_music_mobile/service/ranking/wy_ranking_service.dart';
import 'package:xy_music_mobile/service/square/kg_square_service.dart';
import 'package:xy_music_mobile/service/square/wy_square_service.dart';
import 'package:xy_music_mobile/service/tx_music_service.dart';
import 'package:xy_music_mobile/service/wy_music_service.dart';

///音乐服务
void _registerMusicService() {
  ///注册酷狗服务
  MusicServiceProviderMange.register(KGMusicServiceImpl());

  ///咪咕服务
  MusicServiceProviderMange.register(MgMusicServiceImpl());

  ///QQ音乐服务
  MusicServiceProviderMange.register(TxMusicServiceImpl());

  ///网易音乐
  MusicServiceProviderMange.register(WyMusicServiceImpl());
}

///歌单服务
void _registerSquareService() {
  ///酷狗歌单服务注册
  SquareServiceProviderMange.register(KgSquareServiceImpl());
  //网易歌单
  SquareServiceProviderMange.register(WySquareServiceImpl());
}

///排行榜服务
void _registerRankingService() {
  ///酷狗排行榜服务注册
  SongRankingServiceProviderMange.register(KgRankingListServiceImpl());
  //网易排行榜
  SongRankingServiceProviderMange.register(WyRankingListServiceImpl());
}

///注册服务方法、调用交给Application类去管理
void register() {
  _registerMusicService();
  _registerSquareService();
  _registerRankingService();
}
