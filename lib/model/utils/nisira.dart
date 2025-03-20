class Nisira {
  static const String pass1 = "!ABCDEFGHIJKLLLMNOPQRSTUVWXYZabcdefrgihklllmnopqrstuvwxyz1234567890 @%+";
  static const String pass2 = "3|°!#\$%&/()=?¡'¿<}~ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒƒáíóúñÑª¿®¦ÁÂÀ©¦ãÃ@6+";
  static const List<String> v1 = ["!","A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "L", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "r", "g", "i", "h", "k", "l", "l", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", " ", "@", "%", "+"];
  static const List<String> v2 = ["3","|", "°", "!", "#", "\$", "%", "&", "/", "(", ")", "=", "?", "¡", "'", "¿", "<", "}", "~", "Ç", "ü", "é", "â", "ä", "à", "å", "ç", "ê", "ë", "è", "ï", "î", "ì", "Ä", "Å", "É", "æ", "Æ", "ô", "ö", "ò", "û", "ù", "ÿ", "Ö", "Ü", "ø", "£", "Ø", "×", "ƒ", "á", "í", "ó", "ú", "ñ", "Ñ", "ª", "¿", "®", "¦", "Á", "Â", "À", "©", "¦", "ã", "Ã", "@", "6", "+"];

  static String? encriptar({String? pass}){
    if(pass == null) return null;
    String encript = '';
    for(var i = 0; i< pass.length; i++){
      if(!pass1.contains(pass[i])){
        encript += pass[i];
      }else{
        for(var j = 0; j < v1.length; j++){
          if(v1[j].compareTo(pass[i]) == 0){
            encript += v2[j];
            break;
          }
        }
      }
    }
    return encript;
  }

  static String? desencriptar({String? pass}){
    if(pass == null) return null;
    String encript = '';
    for(var i = 0; i < pass.length ;i++){
      if(!pass2.contains(pass[i])){
        encript += pass[i];
      }else{
        for(var j = 0; j < v2.length ; j++){
          if(v2[j].compareTo(pass[i]) == 0){
            encript += v1[j];
            break;
          }
        }
      }
    }
    return encript;
  }
}