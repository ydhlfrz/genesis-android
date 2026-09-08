package com.genesis.gacha;
import android.content.*;
import android.security.keystore.*;
import android.util.Base64;
import java.security.KeyStore;
import javax.crypto.*;
import javax.crypto.spec.GCMParameterSpec;
import org.json.JSONObject;
final class SessionStore {
 private final android.content.SharedPreferences prefs;
 SessionStore(Context c){prefs=c.getApplicationContext().getSharedPreferences("auth-session",Context.MODE_PRIVATE);}
 private javax.crypto.SecretKey key() throws Exception {
  KeyStore ks=KeyStore.getInstance("AndroidKeyStore");ks.load(null);
  if(!ks.containsAlias("genesis.session")){KeyGenerator g=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");g.init(new KeyGenParameterSpec.Builder("genesis.session",KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());g.generateKey();}
  return (javax.crypto.SecretKey)ks.getKey("genesis.session",null);
 }
 void save(JSONObject data) throws Exception {Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.ENCRYPT_MODE,key());String blob=Base64.encodeToString(c.doFinal(data.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8)),Base64.NO_WRAP);prefs.edit().putString("blob",blob).putString("iv",Base64.encodeToString(c.getIV(),Base64.NO_WRAP)).apply();}
 JSONObject load() throws Exception {String blob=prefs.getString("blob",null);if(blob==null)return null;Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.DECRYPT_MODE,key(),new GCMParameterSpec(128,Base64.decode(prefs.getString("iv",""),Base64.NO_WRAP)));return new JSONObject(new String(c.doFinal(Base64.decode(blob,Base64.NO_WRAP)),java.nio.charset.StandardCharsets.UTF_8));}
 void clear(){prefs.edit().clear().apply();}
}
