/*
 * @Description: 
 * @Author: chenzedeng
 * @Date: 2021-05-23 15:07:50
 * @LastEditTime: 2021-05-23 20:01:50
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:xy_music_mobile/model/music_entity.dart';
import 'package:xy_music_mobile/model/source_constant.dart';

import 'music_service.dart';
import '/util/index.dart' as util;
import '/util/lrc_decode.dart';

class KGMusicServiceImpl extends MusicService {
  ///默认请求配置
  final Options _options = Options(headers: {
    "KG-RC": "1",
    "KG-THash": "expand_search_manager.cpp:852736169:451",
    "User-Agent": "lx-music request"
  });

  @override
  Future<List<MusicEntity>> searchMusic(String keyword,
      {int size = 10, int current = 0}) async {
    Map result = await util.HttpUtil.get(
        "http://ioscdn.kugou.com/api/v3/search/song",
        data: {
          "keyword": keyword,
          "page": current,
          "pagesize": size,
          "showtype": 10,
          "plat": 2,
          "version": 7910,
          "tag": 1,
          "correct": 1,
          "privilege": 1,
          "sver": 5
        });
    return (result["data"]["info"] as List).map((e) {
      var entity = MusicEntity(
          originData: e,
          singer: e["singername"],
          songName: e["songname"],
          songnameOriginal: e["songname_original"],
          source: MusicSourceConstant.kg,
          songmId: e["audio_id"].toString(),
          albumId: e["album_id"].toString(),
          duration: e["duration"],
          durationStr: util.getTimeStamp(e["duration"]),
          albumName: e["album_name"]);
      return setQuality(entity, e);
    }).toList();
  }

  ///获取歌词
  @override
  Future<String> getLyric(MusicEntity entity) async {
    Map result = await util.HttpUtil.get("http://lyrics.kugou.com/search",
        data: {
          "ver": 1,
          "man": "yes",
          "client": "pc",
          "keyword": entity.songName,
          "hash": entity.hash,
          "timelength": entity.duration
        },
        options: _options);
    if (result["status"] == 200) {
      var id;
      var accesskey;
      List<Map<String, dynamic>> candidates = (result["candidates"] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (candidates.isEmpty) {
        return Future.error("获取歌词失败");
      }
      id = candidates[0]["id"];
      accesskey = candidates[0]["accesskey"];
      //成功进行下载歌词
      Map lrcJson = await util.HttpUtil.get("http://lyrics.kugou.com/download",
          data: {
            "client": "pc",
            "id": id,
            "accesskey": accesskey,
            "fmt": "krc",
            "charset": "utf8",
            "ver": 1
          },
          options: _options);
      if (lrcJson["status"] != 200) {
        return Future.error("下载歌词失败");
      }
      return lrcDecode(lrcJson["content"]);
    } else {
      return Future.error("获取歌词失败");
    }
  }

  ///获取播放Url
  @override
  Future<MusicEntity> getMusicPlayUrl(MusicEntity entity) async {
    Map result = await util.HttpUtil.get("https://api.gmit.vip/Api/KuGou",
        data: {"format": "json", "id": entity.hash});
    if (result["code"] != 200) {
      return Future.error("解析失败");
    }
    entity.playUrl = result["data"]["url"];
    return entity;
  }

  @override
  Future<List<Map<String, dynamic>>> getMusicSquareDetail(
      Map<String, dynamic> params) {
    // TODO: implement getMusicSquareDetail
    throw UnimplementedError();
  }

  @override
  Future<String> getPic(MusicEntity entity) async {
    Map result = await util.HttpUtil.post(
        "http://media.store.kugou.com/v1/get_res_privilege",
        data: {
          "appid": 1001,
          "area_code": '1',
          "behavior": 'play',
          "clientver": '9020',
          "need_hash_offset": 1,
          "relate": 1,
          "resource": [
            {
              "album_audio_id": entity.songmId,
              "album_id": entity.albumId,
              "hash": entity.hash,
              "id": 0,
              "name": '${entity.singer} - ${entity.songName}.mp3',
              "type": 'audio',
            },
          ],
          "token": '',
          "userid": 2626431536,
          "vip": 1,
        },
        options: _options.copyWith(contentType: ContentType.json.value));
    if (result["error_code"] != 0) {
      return Future.error("图片获取失败");
    }
    Map info = result["data"][0]["info"];
    String url = info["image"];
    if (info.containsKey("imgsize")) {
      int size = info["imgsize"][0];
      url = url.replaceAll("{size}", size.toString());
    }
    return url;
  }

  ///设置音质
  @override
  MusicEntity setQuality(MusicEntity entity, Map map) {
    //Todo 从设置里获取音频设置
    //默认最高品质
    var qualitys = MusicSupportQualitys.kg.reversed.toList();
    if (map.containsKey("sqfilesize")) {
      entity.quality = qualitys[0];
      entity.hash = map["sqhash"];
      entity.qualityFileSize = map["sqfilesize"];
    } else if (map.containsKey("320filesize")) {
      entity.quality = qualitys[1];
      entity.hash = map["320hash"];
      entity.qualityFileSize = map["320filesize"];
    } else {
      entity.quality = qualitys[2];
      entity.hash = map["hash"];
      entity.qualityFileSize = map["filesize"];
    }
    return entity;
  }
}
