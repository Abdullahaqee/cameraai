class ChatModel {

  late bool isme;

  late String massage;

  String? base64EncodedImage;

  ChatModel({
      required this.isme, required this.massage, this.base64EncodedImage}
      );

  ChatModel.fromJson(Map<String,dynamic> json){
    isme = json['is_me'];
    massage = json['massage'];
    base64EncodedImage = json['image'];
  }

  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String,dynamic>{};
    data ['is_me'] = isme;
    data ['massage'] = massage;
    data ['image'] = base64EncodedImage;
    return data;

  }
}