import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._(); static final i=ApiClient._();
  Future<String?> _token() async => (await SharedPreferences.getInstance()).getString('api_token');
  Future<Map<String,String>> _headers({bool jsonBody=true}) async { final t=await _token(); return {if(jsonBody)'Content-Type':'application/json',if(t!=null&&t.isNotEmpty)'Authorization':'Bearer $t'}; }
  void _requestLog(String method,String path)=>debugPrint('[API] --> $method ${ApiConfig.baseUrl}$path');
  void _responseLog(String method,String path,int code,int ms)=>debugPrint('[API] <-- $method $path [$code] ${ms}ms');
  dynamic _decode(http.Response r){ dynamic body; try{body=r.body.isEmpty?null:jsonDecode(r.body);}catch(_){body=null;} if(r.statusCode<200||r.statusCode>=300){throw ApiException(body is Map&&body['message']!=null?body['message'].toString():'Request failed (${r.statusCode})',statusCode:r.statusCode);} return body; }
  Future<dynamic> request(String method,String path,{Object? body}) async {
    final sw=Stopwatch()..start(); _requestLog(method,path);
    try { final u=Uri.parse('${ApiConfig.baseUrl}$path'), h=await _headers(), b=body==null?null:jsonEncode(body); late http.Response r;
      switch(method){case 'GET':r=await http.get(u,headers:h).timeout(ApiConfig.timeout);break;case 'POST':r=await http.post(u,headers:h,body:b).timeout(ApiConfig.timeout);break;case 'PUT':r=await http.put(u,headers:h,body:b).timeout(ApiConfig.timeout);break;case 'PATCH':r=await http.patch(u,headers:h,body:b).timeout(ApiConfig.timeout);break;case 'DELETE':r=await http.delete(u,headers:h,body:b).timeout(ApiConfig.timeout);break;default:throw ArgumentError('Unsupported HTTP method $method');}
      _responseLog(method,path,r.statusCode,sw.elapsedMilliseconds); return _decode(r);
    } on ApiException { rethrow; } on SocketException catch(e){debugPrint('[API] !! $method $path NO NETWORK: $e');throw const ApiException('Internet connection required. Please connect and try again.',networkError:true);} on TimeoutException catch(e){debugPrint('[API] !! $method $path TIMEOUT: $e');throw const ApiException('Server is not responding. Please try again.',networkError:true);} on http.ClientException catch(e){debugPrint('[API] !! $method $path CLIENT: $e');throw const ApiException('Cannot connect to the server. Please check your connection.',networkError:true);} catch(e){debugPrint('[API] !! $method $path ERROR: $e');rethrow;}
  }
  Future<dynamic> get(String p)=>request('GET',p); Future<dynamic> post(String p,[Object? b])=>request('POST',p,body:b); Future<dynamic> put(String p,[Object? b])=>request('PUT',p,body:b); Future<dynamic> patch(String p,[Object? b])=>request('PATCH',p,body:b); Future<dynamic> delete(String p,[Object? b])=>request('DELETE',p,body:b);
  Future<dynamic> uploadBytes(String path,String field,Uint8List bytes,{String filename='upload.jpg'}) async { final sw=Stopwatch()..start(); _requestLog('UPLOAD',path); try { final req=http.MultipartRequest('POST',Uri.parse('${ApiConfig.baseUrl}$path')); final t=await _token(); if(t!=null)req.headers['Authorization']='Bearer $t'; req.files.add(http.MultipartFile.fromBytes(field,bytes,filename:filename)); final streamed=await req.send().timeout(ApiConfig.timeout); final r=await http.Response.fromStream(streamed); _responseLog('UPLOAD',path,r.statusCode,sw.elapsedMilliseconds); return _decode(r); } on SocketException {throw const ApiException('Internet connection required. Please connect and try again.',networkError:true);} on TimeoutException {throw const ApiException('Server is not responding. Please try again.',networkError:true);} }
}
