class ApiException implements Exception {
  final String message; final int? statusCode; final bool networkError;
  const ApiException(this.message,{this.statusCode,this.networkError=false});
  @override String toString()=>message;
}
